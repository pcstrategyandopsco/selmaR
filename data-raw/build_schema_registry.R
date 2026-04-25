# Build the internal schema registry from the SELMA OpenAPI specs.
#
# Run this script whenever the OpenAPI specs are updated:
#   source("data-raw/build_schema_registry.R")
#
# Output: R/sysdata.rda containing .selma_schemas — a nested list:
#   .selma_schemas$v2$students$fields       — character vector of post-clean_names field names
#   .selma_schemas$v2$students$id_columns   — subset of fields that are ID columns
#   .selma_schemas$v3$students$fields
#   .selma_schemas$v3$students$id_columns

library(jsonlite)
library(janitor)
library(usethis)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Resolve a $ref string to a schema object within the spec.
# Only handles local refs of the form "#/components/schemas/Name".
resolve_ref <- function(ref, spec) {
  parts <- strsplit(sub("^#/", "", ref), "/")[[1]]
  obj <- spec
  for (part in parts) obj <- obj[[part]]
  obj
}

# Extract all top-level property names from a schema object.
# Handles direct properties and allOf/anyOf composition.
extract_properties <- function(schema, spec, depth = 0L) {
  if (depth > 5L) return(character(0))  # guard against circular refs

  props <- character(0)

  if (!is.null(schema[["$ref"]])) {
    schema <- resolve_ref(schema[["$ref"]], spec)
    return(extract_properties(schema, spec, depth + 1L))
  }

  if (!is.null(schema$properties)) {
    props <- c(props, names(schema$properties))
  }

  for (subschema in c(schema$allOf, schema$anyOf, schema$oneOf)) {
    props <- c(props, extract_properties(subschema, spec, depth + 1L))
  }

  unique(props)
}

# Apply janitor-style name cleaning to a character vector.
# Mirrors what janitor::clean_names() does to column names.
clean_field_names <- function(x) {
  janitor::make_clean_names(x)
}

# Identify which (cleaned) field names are ID columns.
# Matches: "id", anything ending in "_id", anything ending in "id" (e.g. progid).
identify_id_columns <- function(fields) {
  grep("(^id$|_id$|id$)", fields, value = TRUE)
}

# Extract valid filter query parameter names for a collection GET endpoint.
# Skips pagination params (page, itemsPerPage) — those are handled by selma_get().
extract_query_params <- function(path_obj) {
  params <- path_obj$get$parameters %||% list()
  query  <- Filter(function(p) identical(p[["in"]], "query"), params)
  skip   <- c("page", "itemsPerPage", "order", "order[]")
  names_vec <- vapply(query, function(p) p[["name"]] %||% "", character(1L))
  sort(unique(names_vec[!names_vec %in% skip & nchar(names_vec) > 0]))
}

# Extract the schema name for a collection GET endpoint's items.
# Returns NULL if not found.
collection_item_ref <- function(path_obj) {
  resp <- path_obj$get$responses[["200"]]
  if (is.null(resp)) return(NULL)

  # Try application/json first (plain array of items)
  json_schema <- resp$content[["application/json"]]$schema
  if (!is.null(json_schema$items[["$ref"]])) {
    return(json_schema$items[["$ref"]])
  }

  # Try application/ld+json (allOf with HydraCollectionBaseSchema)
  ld_schema <- resp$content[["application/ld+json"]]$schema
  if (!is.null(ld_schema)) {
    for (sub in ld_schema$allOf) {
      if (!is.null(sub$properties$member$items[["$ref"]])) {
        return(sub$properties$member$items[["$ref"]])
      }
    }
  }

  NULL
}

# ---------------------------------------------------------------------------
# Process one spec file into a named list of entity schemas
# ---------------------------------------------------------------------------

process_spec <- function(spec_path, path_prefix) {
  message("Reading ", basename(spec_path), "...")
  spec <- jsonlite::read_json(spec_path, simplifyVector = FALSE)

  paths <- spec$paths
  entity_schemas <- list()

  for (path in names(paths)) {
    # Skip item endpoints (contain {id}) and non-GET paths
    if (grepl("\\{", path)) next
    if (is.null(paths[[path]]$get)) next

    # Derive entity name from path (strip leading /prefix/)
    entity <- sub(paste0("^/", path_prefix, "/"), "", path)
    entity <- gsub("-", "_", entity)  # normalise hyphens

    ref <- collection_item_ref(paths[[path]])
    if (is.null(ref)) next

    schema <- tryCatch(
      resolve_ref(ref, spec),
      error = function(e) {
        message("  WARNING: could not resolve ref '", ref, "' for entity '", entity, "': ", e$message)
        NULL
      }
    )
    if (is.null(schema)) next

    raw_fields <- extract_properties(schema, spec)
    if (length(raw_fields) == 0L) next

    cleaned <- clean_field_names(raw_fields)
    id_cols  <- identify_id_columns(cleaned)

    entity_schemas[[entity]] <- list(
      fields     = cleaned,
      id_columns = id_cols,
      params     = extract_query_params(paths[[path]])
    )
  }

  message("  Extracted schemas for ", length(entity_schemas), " entities.")
  entity_schemas
}

# ---------------------------------------------------------------------------
# Build registry for both versions
# ---------------------------------------------------------------------------

v2_schemas <- process_spec(
  "data-raw/openapi/selma_v2.json",
  path_prefix = "app"
)

v3_schemas <- process_spec(
  "data-raw/openapi/selma_v3.json",
  path_prefix = "api"
)

.selma_schemas <- list(
  v2 = v2_schemas,
  v3 = v3_schemas
)

# ---------------------------------------------------------------------------
# Save as internal package data
# ---------------------------------------------------------------------------

usethis::use_data(.selma_schemas, internal = TRUE, overwrite = TRUE)

message("Done. .selma_schemas saved to R/sysdata.rda")
message("  v2 entities: ", length(v2_schemas))
message("  v3 entities: ", length(v3_schemas))
