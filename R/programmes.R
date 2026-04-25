#' Fetch programme definitions from SELMA
#'
#' Retrieves programme (qualification) records.
#'
#' Use the `filter` argument to pass server-side query parameters sourced
#' directly from the SELMA OpenAPI spec. Valid parameter names for the active
#' API version are stored in `.selma_schemas[[version]]$programmes$params`.
#'
#' @inheritParams selma_students
#' @return A tibble of programme records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' programmes <- selma_programmes()
#' programmes <- selma_programmes(filter = list(title = "Certificate"))
#' }
selma_programmes <- make_entity_fetcher("programmes")
