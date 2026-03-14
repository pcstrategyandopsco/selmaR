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

  full_url <- paste0(con$base_url, "app/", endpoint)

  base_query <- list(page = 1L, itemsPerPage = items_per_page)
  query <- if (!is.null(query_params)) {
    modifyList(base_query, query_params)
  } else {
    base_query
  }

  # First request
  resp_data <- selma_request(con, full_url, query)

  # Check if paginated (has hydra:totalItems)
  if (!is.null(resp_data[["hydra:totalItems"]])) {
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
    "i" = paste("Endpoint:", endpoint)
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
        paste("SELMA API error. Status:", status, "URL:", url)
      }
    }) |>
    httr2::req_perform()

  httr2::resp_body_json(resp, simplifyVector = TRUE)
}

#' Fetch all pages from a paginated SELMA endpoint
#' @noRd
selma_fetch_all_pages <- function(con, url, query, initial_data,
                                  items_per_page, max_pages, .progress) {
  total_items <- initial_data[["hydra:totalItems"]]
  total_pages <- ceiling(total_items / items_per_page)
  total_pages <- min(total_pages, max_pages)

  if (.progress) {
    cli_alert_info("Fetching {total_pages} page{?s} ({total_items} items) from SELMA")
  }

  all_data <- vector("list", total_pages)

  for (current_page in seq_len(total_pages)) {
    if (.progress && (current_page %% 10 == 0 || current_page == total_pages)) {
      cli_alert_info("  Page {current_page}/{total_pages}")
    }

    query$page <- current_page
    page_data <- selma_request(con, url, query)

    members <- page_data[["hydra:member"]]
    if (!is.null(members)) {
      all_data[[current_page]] <- as.data.frame(members)
    }
  }

  combined <- bind_rows(all_data)
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
#' Handles Hydra JSON-LD format quirks: drops `@id` URI columns, renames
#' `id_2` to `id`, applies `clean_names()`, and converts ID columns to
#' character for safe joining.
#'
#' @param df Raw data frame from SELMA API.
#' @param entity_type One of `"students"`, `"enrolments"`, `"intakes"`,
#'   `"components"`, `"programmes"`.
#' @return A cleaned tibble.
#' @noRd
standardize_selma_data <- function(df, entity_type) {
  if (nrow(df) == 0) return(as_tibble(df))

  # Drop Hydra @id column (URI path like "/app/students/123")
  if ("id" %in% names(df) && "id_2" %in% names(df)) {
    df <- select(df, -"id", -any_of("type"))
  } else if ("id" %in% names(df) && any(grepl("^/app/", df$id))) {
    df <- select(df, -"id", -any_of("type"))
  }

  # Rename id_2 to id

  if ("id_2" %in% names(df)) {
    df <- rename(df, id = "id_2")
  }

  df <- clean_names(df)


  # Convert ID columns to character for safe joining
  # Explicit mappings for core entities, plus generic pattern for all others
  id_cols <- switch(entity_type,
    students = "id",
    enrolments = c("id", "student_id", "intake_id"),
    intakes = c("intakeid", "progid"),
    components = c("compenrid", "compid", "enrolid", "studentid"),
    programmes = c("progid"),
    notes = c("noteid", "student_id", "enrolmentid"),
    addresses = c("addressid", "studentid", "contactid", "orgid"),
    contacts = "id",
    classes = c("id", "campusid"),
    organisations = c("id", "orgparentid"),
    campuses = "id",
    student_contacts = c("id", "studentid", "contactid"),
    student_programmes = c("student_id", "enrol_id", "prog_id", "parent_prog_id"),
    student_relations = "id",
    student_classes = c("student_id", "enrol_id", "campus_id"),
    enrolment_awards = c("award_id", "enrol_id", "prog_id", "parent_prog_id"),
    component_attempts = c("component_attempt_id", "compenrid"),
    component_definitions = "compid",
    class_enrolment = c("id", "enrolid", "studentid"),
    intake_fees = "id",
    grading_schemes = "id",
    custom_fields = "id",
    users = "id",
    marketing_sources = "id",
    {
      # Default: convert any column ending in "id" or named "id" to character
      id_pattern <- grep("(^id$|_id$|id$)", names(df), value = TRUE)
      id_pattern
    }
  )

  for (col in id_cols) {
    if (col %in% names(df)) {
      df[[col]] <- as.character(df[[col]])
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

  data <- standardize_selma_data(data, entity_label)

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
  url <- paste0(con$base_url, "app/", endpoint, "/", id)
  resp <- selma_request(con, url)
  # Remove JSON-LD metadata
  resp[c("@context", "@id", "@type")] <- NULL
  if (length(resp) == 0) {
    abort(c(
      paste0("No record found for ", endpoint, "/", id),
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
  clean_names(result)
}
