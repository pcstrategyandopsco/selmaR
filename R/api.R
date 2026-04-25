#' Fetch data from a SELMA API endpoint
#'
#' Generic paginated fetcher that handles Hydra JSON-LD pagination. For most
#' use cases, prefer the entity-specific functions like [selma_students()] or
#' [selma_enrolments()].
#'
#' @param con A `selma_connection` object from [selma_connect()], or `NULL`
#'   to use the connection stored by [selma_connect()].
#' @param endpoint API endpoint path (e.g. `"students"`, `"enrolments"`).
#' @param query_params Named list of additional query parameters.
#' @param items_per_page Number of items per page (default 30).
#' @param max_pages Maximum pages to fetch (default `Inf` for all).
#' @param .progress Show progress messages via cli (default `TRUE`).
#' @return A tibble of results with `clean_names()` applied.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' students <- selma_get(endpoint = "students", items_per_page = 100)
#' }
selma_get <- function(con = NULL, endpoint, query_params = NULL,
                      items_per_page = 30L, max_pages = Inf,
                      .progress = TRUE) {
  con <- selma_get_connection(con)

  cfg      <- api_cfg(con$api_version)
  full_url <- str_c(con$base_url, cfg$path_prefix, resolve_endpoint(endpoint, con$api_version))

  base_query <- list(page = 1L)
  if (!is.null(cfg$page_size_param)) {
    base_query[[cfg$page_size_param]] <- items_per_page
  }
  query <- if (!is.null(query_params)) modifyList(base_query, query_params) else base_query

  # First request
  resp_data <- selma_request(con, full_url, query)

  # Check if paginated
  if (!is.null(resp_data[[cfg$total_key]])) {
    return(selma_fetch_all_pages(
      con, full_url, query, resp_data, items_per_page, max_pages, .progress
    ))
  }

  # Non-paginated response (e.g. intake_enrolments)
  if (!is.null(resp_data)) {
    if (.progress) cli_alert_info("Processing non-paginated SELMA response")
    return(flatten_intake_enrolment_json(resp_data))
  }

  abort(c(
    "Unexpected SELMA API response format.",
    "i" = str_c("Endpoint: ", endpoint)
  ))
}

#' Make a single SELMA API request
#' @noRd
selma_request <- function(con, url, query = NULL) {
  resp <- httr2::request(url) |>
    httr2::req_headers(Authorization = con$token) |>
    httr2::req_url_query(!!!query) |>
    httr2::req_error(body = function(resp) {
      status <- httr2::resp_status(resp)
      if (status == 401L) {
        "SELMA bearer token has expired or is invalid. Re-authenticate with selma_connect()."
      } else {
        str_c("SELMA API error. Status: ", status, " URL: ", url)
      }
    }) |>
    httr2::req_perform()

  httr2::resp_body_json(resp, simplifyVector = TRUE)
}

#' Fetch all pages from a paginated SELMA endpoint
#' @noRd
selma_fetch_all_pages <- function(con, url, query, initial_data,
                                  items_per_page, max_pages, .progress) {
  cfg         <- api_cfg(con$api_version)
  total_items <- initial_data[[cfg$total_key]]

  # Derive actual page size from first response — v3 doesn't expose itemsPerPage
  first_members    <- extract_members(initial_data, con$api_version)
  actual_page_size <- max(nrow(bind_rows(first_members)), 1L)
  total_pages      <- min(ceiling(total_items / actual_page_size), max_pages)

  if (.progress) {
    cli_alert_info("Fetching {total_pages} page{?s} ({total_items} items) from SELMA")
  }

  all_data <- vector("list", total_pages)

  for (current_page in seq_len(total_pages)) {
    if (.progress && (current_page %% 10 == 0 || current_page == total_pages)) {
      cli_alert_info("  Page {current_page}/{total_pages}")
    }

    query$page <- current_page
    page_data  <- selma_request(con, url, query)
    members    <- extract_members(page_data, con$api_version)

    if (!is.null(members)) {
      all_data[[current_page]] <- bind_rows(members)
    }
  }

  combined <- bind_rows(all_data)
  # Drop JSON-LD metadata before clean_names() to prevent @id → id collision
  combined <- select(combined, -any_of(c("@id", "@type", "@context")))
  clean_names(combined)
}

#' Build a query parameter list, dropping NULLs
#'
#' Returns `NULL` (not an empty list) when all params are NULL, so callers
#' can test `is.null(query_params)` to decide on caching.
#' @noRd
compact_query <- function(...) {
  params <- list(...)
  params <- params[!vapply(params, is.null, logical(1))]
  if (length(params) == 0L) NULL else params
}

#' Standardise raw SELMA data
#'
#' Applies `clean_names()`, strips IRI path references from v3 foreign key
#' columns (e.g. `"/api/students/42"` → `"42"`), and soft-validates fields
#' against the schema registry.
#'
#' JSON-LD metadata columns (`@id`, `@type`, `@context`) are dropped upstream
#' in `selma_fetch_all_pages()` before `clean_names()` runs, so `id` always
#' arrives here as the integer primary key.
#'
#' @param df Raw data frame from SELMA API.
#' @param entity_type API endpoint name used to look up the schema registry.
#' @param api_version `"v2"` or `"v3"`.
#' @return A cleaned tibble.
#' @noRd
standardize_selma_data <- function(df, entity_type, api_version = "v2") {
  if (nrow(df) == 0) return(as_tibble(df))

  cfg <- api_cfg(api_version)

  df <- clean_names(df)

  # Strip IRI references from v3 foreign key columns (e.g. /api/students/42 → "42").
  # v2 foreign keys are integers so is.character() excludes them naturally.
  if (!is.null(cfg$id_uri_pattern)) {
    iri_cols <- names(df)[vapply(df, function(col) {
      is.character(col) && any(str_detect(col, cfg$id_uri_pattern), na.rm = TRUE)
    }, logical(1L))]
    if (length(iri_cols) > 0L) {
      df <- mutate(df, across(all_of(iri_cols), ~ str_extract(.x, "[^/]+$")))
    }
  }

  # Soft field validation — warn when expected fields are absent
  schema <- .selma_schemas[[api_version]][[entity_type]]
  if (!is.null(schema)) {
    missing_fields <- setdiff(schema$fields, names(df))
    if (length(missing_fields) > 0L) {
      cli_warn(c(
        "SELMA {entity_type} ({api_version}): {length(missing_fields)} expected field{?s} missing from response.",
        "i" = str_c(missing_fields, collapse = ", "),
        "i" = "The SELMA API may have changed. Check for a package update."
      ))
    }
  }

  as_tibble(df)
}

#' Flatten nested intake enrolment JSON
#'
#' The `/app/intake_enrolments` endpoint returns a non-paginated nested JSON
#' structure. This function unnests it into a flat tibble.
#'
#' @param json_data Parsed JSON data (named list).
#' @return A flat tibble with clean names.
#' @noRd
flatten_intake_enrolment_json <- function(json_data) {
  if (length(json_data) == 0) {
    cli_alert_warning("Empty intake enrolment response")
    return(tibble())
  }

  json_df <- tibble(
    enrolment_id = names(json_data),
    data = json_data
  ) |>
    unnest_wider("data")

  # Expand address if present
  if ("address" %in% names(json_df)) {
    address_df <- json_df |>
      select("enrolment_id", any_of(c("StudentID", "FirstName", "LastName")), "address") |>
      unnest_longer("address") |>
      unnest_wider("address", names_sep = "_")
  } else {
    address_df <- NULL
  }

  # Expand components if present
  if ("components" %in% names(json_df)) {
    components_df <- json_df |>
      select("enrolment_id", any_of(c("StudentID", "FirstName", "LastName")), "components") |>
      unnest_longer("components") |>
      unnest_wider("components", names_sep = "_")
  } else {
    components_df <- NULL
  }

  # Build join keys
  join_keys <- intersect(
    c("enrolment_id", "StudentID", "FirstName", "LastName"),
    names(json_df)
  )

  result <- json_df |>
    select(-any_of(c("address", "components")))

  if (!is.null(address_df)) {
    result <- left_join(result, address_df, by = join_keys, relationship = "many-to-many")
  }
  if (!is.null(components_df)) {
    result <- left_join(result, components_df, by = join_keys, relationship = "many-to-many")
  }

  clean_names(result)
}

#' Fetch and standardise a SELMA entity (internal helper)
#'
#' Shared logic for all entity fetch functions: check cache, fetch via
#' `selma_get()`, standardise, and optionally cache.
#'
#' @param con A `selma_connection` object, or `NULL` to use the stored
#'   connection.
#' @param endpoint API endpoint path.
#' @param entity_label Label used for caching and standardisation.
#' @param cache,cache_dir,cache_hours Caching parameters.
#' @param items_per_page Items per API page.
#' @param .progress Show progress messages.
#' @return A cleaned tibble.
#' @noRd
selma_fetch_entity <- function(con = NULL, endpoint, entity_label = endpoint,
                               query_params = NULL,
                               cache = FALSE, cache_dir = "selma_cache",
                               cache_hours = 24, items_per_page = 100L,
                               .progress = TRUE) {
  con <- selma_get_connection(con)

  # Skip cache when filtering — cached data is the full dataset
  use_cache <- cache && is.null(query_params)
  path <- cache_path(cache_dir, entity_label)

  if (use_cache && cache_is_fresh(path, cache_hours)) {
    return(cache_load(path, entity_label))
  }

  data <- selma_get(
    con, endpoint,
    query_params = query_params,
    items_per_page = items_per_page,
    .progress = .progress
  )

  data <- standardize_selma_data(data, entity_label, api_version = con$api_version)

  if (use_cache) cache_save(data, path, entity_label)
  data
}

#' Fetch a single record from a SELMA API endpoint
#'
#' Retrieves a single record by ID from any SELMA endpoint. Most SELMA
#' endpoints support `GET /app/{endpoint}/{id}` for single-record access.
#'
#' @param endpoint API endpoint path (e.g. `"students"`, `"enrolments"`).
#' @param id The record ID to fetch.
#' @param con A `selma_connection` object, or `NULL` to use the stored
#'   connection.
#' @return A single-row tibble with `clean_names()` applied.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' student <- selma_get_one("students", "123")
#' enrolment <- selma_get_one("enrolments", "456")
#' }
selma_get_one <- function(endpoint, id, con = NULL) {
  con <- selma_get_connection(con)
  cfg <- api_cfg(con$api_version)
  url <- str_c(con$base_url, cfg$path_prefix, endpoint, "/", id)
  resp <- selma_request(con, url)
  # Remove JSON-LD metadata
  resp[c("@context", "@id", "@type")] <- NULL
  if (length(resp) == 0) {
    abort(c(
      str_c("No record found for ", endpoint, "/", id),
      "i" = "Check that the ID exists in SELMA."
    ))
  }
  # Drop nested lists/objects and replace NULLs with NA
  resp <- lapply(resp, function(x) {
    if (is.null(x)) return(NA)
    if (is.list(x)) return(NA)
    x
  })
  result <- as_tibble(as.data.frame(resp, stringsAsFactors = FALSE))
  standardize_selma_data(result, endpoint, api_version = con$api_version)
}

#' Factory: create a standard entity fetch function driven by the schema registry
#'
#' The returned function accepts a `filter` list whose names must be valid API
#' query parameter names for that entity and version (sourced from the OpenAPI
#' spec via `.selma_schemas`). Unknown params emit a warning and are dropped.
#'
#' @param entity API endpoint name, e.g. `"enrolments"`.
#' @return A function with signature
#'   `(con, filter, cache, cache_dir, cache_hours, items_per_page, .progress)`.
#' @noRd
make_entity_fetcher <- function(entity) {
  force(entity)
  function(con = NULL, filter = list(),
           cache = FALSE, cache_dir = "selma_cache",
           cache_hours = 24, items_per_page = 100L, .progress = TRUE) {

    con   <- selma_get_connection(con)
    valid <- .selma_schemas[[con$api_version]][[entity]]$params %||% character()

    unknown <- setdiff(names(filter), valid)
    if (length(unknown) > 0) {
      cli_warn(c(
        "Unknown filter params for {entity} ({con$api_version}) — ignored:",
        "x" = str_c(unknown, collapse = ", "),
        "i" = "Valid params: {str_c(valid, collapse = ', ')}"
      ))
    }

    query <- filter[intersect(names(filter), valid)]
    query <- Filter(Negate(is.null), query)

    use_cache <- cache && length(query) == 0
    path      <- cache_path(cache_dir, entity)
    if (use_cache && cache_is_fresh(path, cache_hours)) return(cache_load(path, entity))

    data <- selma_get(con, entity,
                      query_params    = if (length(query) > 0) query else NULL,
                      items_per_page  = items_per_page,
                      .progress       = .progress)
    data <- standardize_selma_data(data, entity, api_version = con$api_version)

    if (use_cache) {
      cache_save(data, path, entity)
    } else if (!cache && length(query) == 0 && nrow(data) > 100L) {
      cli_alert_info(
        "Tip: pass {.code cache = TRUE} to save this result locally and skip the API on repeat calls."
      )
    }
    data
  }
}
