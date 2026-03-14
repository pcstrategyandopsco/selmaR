# Status code constants ---------------------------------------------------

#' @title SELMA Enrolment Status Codes
#' @description Single-character codes used in enrolment status fields.
#' @name selma_status_codes
#' @rdname selma_status_codes
NULL

#' @rdname selma_status_codes
#' @export
SELMA_STATUS_CONFIRMED <- "C"

#' @rdname selma_status_codes
#' @export
SELMA_STATUS_COMPLETED <- "FC"

#' @rdname selma_status_codes
#' @export
SELMA_STATUS_INCOMPLETE <- "FI"

#' @rdname selma_status_codes
#' @export
SELMA_STATUS_WITHDRAWN <- "WR"

#' @rdname selma_status_codes
#' @export
SELMA_STATUS_WITHDRAWN_SDR <- "WS"

#' @rdname selma_status_codes
#' @export
SELMA_STATUS_EARLY_WITHDRAWN <- "ER"

#' @rdname selma_status_codes
#' @export
SELMA_STATUS_DEFERRED <- "D"

#' @rdname selma_status_codes
#' @export
SELMA_STATUS_CANCELLED <- "X"

#' @rdname selma_status_codes
#' @export
SELMA_STATUS_PENDING <- "P"

# Funded status groups ----------------------------------------------------

#' @title SELMA Funded Status Groups
#' @description Groups of status codes representing funded enrolments.
#' @name selma_funded_statuses
#' @rdname selma_funded_statuses
NULL

#' @rdname selma_funded_statuses
#' @export
SELMA_FUNDED_STATUSES <- c("C", "FC", "FI")

#' @rdname selma_funded_statuses
#' @export
SELMA_ALL_FUNDED_STATUSES <- c("C", "FC", "FI", "WR", "WS")

# Funding source codes ----------------------------------------------------

#' @title SELMA Funding Source Codes
#' @description Funding source identifiers used in component-level data.
#' @name selma_funding_sources
#' @rdname selma_funding_sources
NULL

#' @rdname selma_funding_sources
#' @export
SELMA_FUNDING_GOVT <- "01"

#' @rdname selma_funding_sources
#' @export
SELMA_FUNDING_INTL <- "02"

#' @rdname selma_funding_sources
#' @export
SELMA_FUNDING_MPTT <- "29"

#' @rdname selma_funding_sources
#' @export
SELMA_FUNDING_YG <- "31"

#' @rdname selma_funding_sources
#' @export
SELMA_FUNDING_DQ37 <- "37"

#' Funding source code to label mapping
#'
#' Named character vector mapping funding source codes to human-readable labels.
#'
#' @export
SELMA_FUNDING_LABELS <- c(
  "01" = "01 Government Funded",
  "02" = "02 International Fee-Paying",
  "29" = "29 MPTT Level 3 and 4",
  "31" = "31 Youth Guarantee",
  "37" = "37 Non-degree Delivery at Levels 3-7 on the NZQCF (DQ3-7)"
)
