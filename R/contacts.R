#' Fetch external contacts from SELMA
#'
#' Retrieves contact records (agents, employers, emergency contacts, etc.).
#' These are external people linked to students, not student records themselves.
#'
#' @inheritParams selma_students
#' @param other_id Filter by the contact's other/external ID.
#' @return A tibble of contact records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' contacts <- selma_contacts()
#' }
selma_contacts <- function(con = NULL, other_id = NULL,
                           cache = FALSE, cache_dir = "selma_cache",
                           cache_hours = 24, items_per_page = 100L,
                           .progress = TRUE) {
  query_params <- compact_query(otherid = other_id)
  selma_fetch_entity(con, "contacts", "contacts",
                     query_params = query_params,
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch student-contact links from SELMA
#'
#' Retrieves the relationships between students and their contacts,
#' including emergency contact and primary contact flags.
#'
#' @inheritParams selma_students
#' @param student_id Filter by student ID.
#' @param contact_id Filter by contact ID.
#' @param relationship Filter by relationship type.
#' @return A tibble with columns including `studentid`, `contactid`,
#'   `isemergency`, `isprimary`, and `relationship`.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' student_contacts <- selma_student_contacts()
#' student_contacts <- selma_student_contacts(student_id = "123")
#' }
selma_student_contacts <- function(con = NULL, student_id = NULL,
                                   contact_id = NULL, relationship = NULL,
                                   cache = FALSE, cache_dir = "selma_cache",
                                   cache_hours = 24, items_per_page = 100L,
                                   .progress = TRUE) {
  query_params <- compact_query(
    studentid = student_id, contactid = contact_id,
    relationship = relationship
  )
  selma_fetch_entity(con, "student_contacts", "student_contacts",
                     query_params = query_params,
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch student relationships from SELMA
#'
#' Retrieves relationship records between students.
#'
#' @inheritParams selma_students
#' @return A tibble of student relationship records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' relations <- selma_student_relations()
#' }
selma_student_relations <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                                    cache_hours = 24, items_per_page = 100L,
                                    .progress = TRUE) {
  selma_fetch_entity(con, "student_relations", "student_relations",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch contact types from SELMA
#'
#' Retrieves the reference list of contact types (e.g. agent, employer).
#'
#' @inheritParams selma_students
#' @return A tibble of contact type codes.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' selma_contact_types()
#' }
selma_contact_types <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                                cache_hours = 24, items_per_page = 100L,
                                .progress = TRUE) {
  selma_fetch_entity(con, "contact_types", "contact_types",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}

#' Fetch student-organisation-contact links from SELMA
#'
#' Retrieves the organisation contacts linked to a specific student.
#'
#' @param student_id The student ID (required).
#' @param con A `selma_connection` object, or `NULL` to use the stored
#'   connection.
#' @return A tibble of student-org-contact records.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' selma_student_org_contacts("123")
#' }
selma_student_org_contacts <- function(student_id, con = NULL) {
  con <- selma_get_connection(con)
  url <- str_c(con$base_url, "app/student_org_contact/", student_id)
  resp <- selma_request(con, url)
  resp[c("@context", "@id", "@type")] <- NULL
  if (length(resp) == 0) return(tibble())
  if (is.data.frame(resp)) return(clean_names(as_tibble(resp)))
  # Hydra collection response
  members <- resp[["hydra:member"]]
  if (!is.null(members)) {
    return(clean_names(as_tibble(as.data.frame(members))))
  }
  result <- as_tibble(as.data.frame(resp, stringsAsFactors = FALSE))
  clean_names(result)
}

#' Fetch contact statuses from SELMA
#'
#' Retrieves the reference list of contact statuses.
#'
#' @inheritParams selma_students
#' @return A tibble of contact status codes.
#' @export
#' @examples
#' \dontrun{
#' selma_connect()
#' selma_contact_statuses()
#' }
selma_contact_statuses <- function(con = NULL, cache = FALSE, cache_dir = "selma_cache",
                                   cache_hours = 24, items_per_page = 100L,
                                   .progress = TRUE) {
  selma_fetch_entity(con, "contact_statuses", "contact_statuses",
                     cache = cache, cache_dir = cache_dir,
                     cache_hours = cache_hours,
                     items_per_page = items_per_page,
                     .progress = .progress)
}
