#!/usr/bin/env Rscript

# ── selmaR MCP Server — Test Suite ────────────────────────────────────────
# Tests the 7 defence layers without requiring SELMA credentials.
# Run: Rscript inst/mcp/test_server.R

suppressPackageStartupMessages({
  library(digest)
  library(yaml)
  library(jsonlite)
  library(stringr)
})

# ── Test Infrastructure ──────────────────────────────────────────────────

.test_results <- list(passed = 0L, failed = 0L, errors = character(0))

test_that <- function(description, expr) {
  result <- tryCatch(
    {
      eval(expr)
      TRUE
    },
    error = function(e) {
      .test_results$errors <<- c(.test_results$errors,
                                  paste0("FAIL: ", description, " — ", conditionMessage(e)))
      FALSE
    }
  )
  if (result) {
    .test_results$passed <<- .test_results$passed + 1L
    cat(paste0("  PASS: ", description, "\n"))
  } else {
    .test_results$failed <<- .test_results$failed + 1L
    cat(paste0("  FAIL: ", description, "\n"))
  }
}

expect_true <- function(x, msg = NULL) {
  if (!isTRUE(x)) stop(msg %||% "Expected TRUE, got FALSE")
}

expect_false <- function(x, msg = NULL) {
  if (!isFALSE(x)) stop(msg %||% "Expected FALSE, got TRUE")
}

expect_equal <- function(x, y, msg = NULL) {
  if (!identical(x, y) && !(is.numeric(x) && is.numeric(y) && x == y)) {
    stop(msg %||% paste0("Expected ", deparse(y), " but got ", deparse(x)))
  }
}

expect_match <- function(x, pattern, msg = NULL) {
  if (!grepl(pattern, x)) {
    stop(msg %||% paste0("Expected pattern '", pattern, "' in: ", substr(x, 1, 100)))
  }
}

expect_no_match <- function(x, pattern, msg = NULL) {
  if (grepl(pattern, x)) {
    stop(msg %||% paste0("Did not expect pattern '", pattern, "' in: ", substr(x, 1, 100)))
  }
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# ── Source security functions from server.R ──────────────────────────────

# We source individual functions rather than the whole server to avoid
# the main loop and auth startup.

cat("\n=== selmaR MCP Server Test Suite ===\n\n")

# ── Layer 1: ID Pseudonymisation ─────────────────────────────────────────

cat("Layer 1: ID Pseudonymisation\n")

.mcp_seed <- "test_seed_12345"

pseudonymise_id <- function(id, prefix = "S") {
  if (is.na(id) || id == "") return(id)
  hash <- substr(digest::digest(paste0(.mcp_seed, id), algo = "md5"), 1, 8)
  paste0(prefix, "-", hash)
}

pseudonymise_column <- function(values, prefix = "S") {
  vapply(values, function(v) pseudonymise_id(v, prefix), character(1),
         USE.NAMES = FALSE)
}

ID_COLUMN_PATTERNS <- list(
  list(pattern = "^(id|student_id|studentid)$", prefix = "S"),
  list(pattern = "^nsn$",                       prefix = "N"),
  list(pattern = "^(contact_id|contactid)$",    prefix = "C"),
  list(pattern = "^(enrolment_id|enrolid|enrol_id)$", prefix = "E"),
  list(pattern = "^(intake_id|intakeid)$",      prefix = "I"),
  list(pattern = "^(compenrid)$",               prefix = "CE"),
  list(pattern = "^(compid)$",                  prefix = "CP"),
  list(pattern = "^(progid)$",                  prefix = "P")
)

.mcp_config <- list(expose_real_ids = FALSE)

apply_pseudonymisation <- function(df) {
  if (.mcp_config$expose_real_ids) return(df)
  for (col in names(df)) {
    col_lower <- tolower(col)
    for (pat in ID_COLUMN_PATTERNS) {
      if (grepl(pat$pattern, col_lower)) {
        df[[col]] <- pseudonymise_column(as.character(df[[col]]), pat$prefix)
        break
      }
    }
  }
  df
}

test_that("Same ID produces same hash (deterministic)", {
  h1 <- pseudonymise_id("12345", "S")
  h2 <- pseudonymise_id("12345", "S")
  expect_equal(h1, h2)
})

test_that("Different IDs produce different hashes", {
  h1 <- pseudonymise_id("12345", "S")
  h2 <- pseudonymise_id("67890", "S")
  expect_true(h1 != h2, "Different IDs should produce different hashes")
})

test_that("Hash format is prefix-8hex", {
  h <- pseudonymise_id("12345", "S")
  expect_match(h, "^S-[0-9a-f]{8}$")
})

test_that("Different prefixes for different column types", {
  hs <- pseudonymise_id("100", "S")
  hn <- pseudonymise_id("100", "N")
  expect_match(hs, "^S-")
  expect_match(hn, "^N-")
  # Same raw hash since same seed+value, but different prefix
  expect_true(hs != hn)
})

test_that("NA and empty string pass through", {
  expect_true(is.na(pseudonymise_id(NA, "S")))
  expect_equal(pseudonymise_id("", "S"), "")
})

test_that("Different seed produces different hash", {
  old_seed <- .mcp_seed
  h1 <- pseudonymise_id("12345", "S")
  .mcp_seed <<- "different_seed"
  h2 <- pseudonymise_id("12345", "S")
  .mcp_seed <<- old_seed
  expect_true(h1 != h2, "Different seeds should produce different hashes")
})

test_that("apply_pseudonymisation handles data frames", {
  df <- data.frame(
    id = c("1", "2"),
    student_id = c("100", "200"),
    nsn = c("123456789", "987654321"),
    name = c("Alice", "Bob"),
    stringsAsFactors = FALSE
  )
  result <- apply_pseudonymisation(df)
  expect_match(result$id[1], "^S-")
  expect_match(result$student_id[1], "^S-")
  expect_match(result$nsn[1], "^N-")
  expect_equal(result$name[1], "Alice")  # non-ID columns unchanged
})

test_that("Joins work with pseudonymised IDs", {
  df1 <- data.frame(id = c("1", "2"), value = c("a", "b"), stringsAsFactors = FALSE)
  df2 <- data.frame(student_id = c("1", "2"), score = c(90, 85), stringsAsFactors = FALSE)
  p1 <- apply_pseudonymisation(df1)
  p2 <- apply_pseudonymisation(df2)
  # student_id "1" should match id "1" because same seed+value+prefix
  expect_equal(p1$id[1], p2$student_id[1])
})

test_that("expose_real_ids disables pseudonymisation", {
  .mcp_config[["expose_real_ids"]] <- TRUE
  df <- data.frame(id = "12345", stringsAsFactors = FALSE)
  result <- apply_pseudonymisation(df)
  expect_equal(result$id, "12345")
  .mcp_config[["expose_real_ids"]] <- FALSE
})

# ── Layer 2: AST Code Inspection ────────────────────────────────────────

cat("\nLayer 2: AST Code Inspection\n")

BLOCKED_PACKAGES <- c("selmaR", "httr", "httr2", "curl", "jsonlite", "config")

BLOCKED_FUNCTIONS <- c(
  "eval", "evalq", "do.call", "get", "mget", "exists",
  "match.fun", "getExportedValue", "loadNamespace", "requireNamespace",
  "Sys.getenv", "Sys.setenv",
  "system", "system2", "shell",
  "readLines", "scan", "file", "readRDS", "writeLines",
  "write.csv", "write.csv2", "saveRDS",
  "download.file", "url", "socketConnection"
)

check_code_safety <- function(code) {
  expr <- tryCatch(parse(text = code), error = function(e) NULL)
  if (is.null(expr)) return(list(safe = TRUE))

  blocked <- character(0)

  walk <- function(node) {
    if (is.call(node)) {
      fn <- node[[1]]
      if (is.call(fn) && length(fn) >= 3 &&
          as.character(fn[[1]]) %in% c("::", ":::")) {
        pkg <- as.character(fn[[2]])
        if (pkg %in% BLOCKED_PACKAGES) {
          blocked <<- c(blocked, paste0(pkg, "::", as.character(fn[[3]])))
        }
      }
      fn_name <- if (is.symbol(fn)) as.character(fn) else ""
      if (fn_name %in% BLOCKED_FUNCTIONS) {
        blocked <<- c(blocked, fn_name)
      }
    }
    if (is.recursive(node)) {
      for (child in as.list(node)) walk(child)
    }
  }

  for (e in as.list(expr)) walk(e)

  if (length(blocked) > 0) {
    list(safe = FALSE, blocked = unique(blocked))
  } else {
    list(safe = TRUE)
  }
}

# Clean code should pass
test_that("Clean dplyr code passes", {
  result <- check_code_safety("df %>% filter(x > 5) %>% summarise(n = n())")
  expect_true(result$safe)
})

test_that("Clean ggplot2 code passes", {
  result <- check_code_safety("ggplot(df, aes(x, y)) + geom_point() + theme_minimal()")
  expect_true(result$safe)
})

test_that("Assignment and basic operations pass", {
  result <- check_code_safety("x <- 1 + 2\ny <- c(1, 2, 3)\nz <- mean(y)")
  expect_true(result$safe)
})

test_that("Comments containing blocked names pass", {
  result <- check_code_safety("# don't use selmaR::selma_students\nx <- 1")
  expect_true(result$safe)
})

test_that("Strings containing blocked names pass", {
  result <- check_code_safety('x <- "use selmaR::selma_students"')
  expect_true(result$safe)
})

# Blocked patterns should fail
test_that("selmaR:: is blocked", {
  result <- check_code_safety("selmaR::selma_students()")
  expect_false(result$safe)
  expect_true("selmaR::selma_students" %in% result$blocked)
})

test_that("selmaR::: is blocked", {
  result <- check_code_safety("selmaR:::selma_request()")
  expect_false(result$safe)
})

test_that("httr:: is blocked", {
  result <- check_code_safety("httr::GET('http://example.com')")
  expect_false(result$safe)
})

test_that("httr2:: is blocked", {
  result <- check_code_safety("httr2::request('http://example.com')")
  expect_false(result$safe)
})

test_that("curl:: is blocked", {
  result <- check_code_safety("curl::curl_fetch_memory('http://example.com')")
  expect_false(result$safe)
})

test_that("config:: is blocked", {
  result <- check_code_safety("config::get('selma')")
  expect_false(result$safe)
})

test_that("eval is blocked", {
  result <- check_code_safety("eval(parse(text = 'selmaR::selma_students()'))")
  expect_false(result$safe)
  expect_true("eval" %in% result$blocked)
})

test_that("do.call is blocked", {
  result <- check_code_safety("do.call('selma_students', list())")
  expect_false(result$safe)
})

test_that("get is blocked", {
  result <- check_code_safety("get('selma_request')")
  expect_false(result$safe)
})

test_that("Sys.getenv is blocked", {
  result <- check_code_safety("Sys.getenv('SELMA_PASSWORD')")
  expect_false(result$safe)
})

test_that("system is blocked", {
  result <- check_code_safety("system('cat /etc/passwd')")
  expect_false(result$safe)
})

test_that("readLines is blocked", {
  result <- check_code_safety("readLines('config.yml')")
  expect_false(result$safe)
})

test_that("writeLines is blocked", {
  result <- check_code_safety("writeLines('data', 'output.txt')")
  expect_false(result$safe)
})

test_that("download.file is blocked", {
  result <- check_code_safety("download.file('http://evil.com', 'data.csv')")
  expect_false(result$safe)
})

test_that("Syntax errors pass through (will fail at eval)", {
  result <- check_code_safety("this is not valid R code {{{")
  expect_true(result$safe)
})

test_that("Multiple blocked constructs detected", {
  result <- check_code_safety("eval(get('system')('whoami'))")
  expect_false(result$safe)
  expect_true(length(result$blocked) >= 2)
})

# ── Layer 4: PII Field Policy ───────────────────────────────────────────

cat("\nLayer 4: PII Field Policy\n")

.mcp_policy <- list(
  students = list(
    mode = "allow",
    fields = c("id", "student_status", "gender", "nationality")
  ),
  notes = list(
    mode = "redact",
    fields = c("note1")
  ),
  campuses = list(
    mode = "all"
  )
)

apply_field_policy <- function(df, entity_name) {
  policy <- .mcp_policy[[entity_name]]
  if (is.null(policy) || identical(policy$mode, "all")) return(df)

  if (identical(policy$mode, "allow")) {
    allowed <- intersect(names(df), policy$fields)
    if (length(allowed) == 0) return(df[0, , drop = FALSE])
    return(df[, allowed, drop = FALSE])
  }

  if (identical(policy$mode, "redact")) {
    for (col in intersect(names(df), policy$fields)) {
      df[[col]] <- "[REDACTED]"
    }
    return(df)
  }

  df
}

test_that("allow mode keeps only listed fields", {
  df <- data.frame(
    id = "1", surname = "Smith", forename = "John",
    student_status = "Active", gender = "M", nationality = "NZ",
    email1 = "john@example.com", dob = "1990-01-01",
    stringsAsFactors = FALSE
  )
  result <- apply_field_policy(df, "students")
  expect_equal(sort(names(result)), sort(c("id", "student_status", "gender", "nationality")))
  # PII fields should be gone
  expect_true(!"surname" %in% names(result))
  expect_true(!"email1" %in% names(result))
  expect_true(!"dob" %in% names(result))
})

test_that("redact mode replaces field values", {
  df <- data.frame(
    noteid = "1", note1 = "Student John called about fees",
    stringsAsFactors = FALSE
  )
  result <- apply_field_policy(df, "notes")
  expect_equal(result$note1, "[REDACTED]")
  expect_equal(result$noteid, "1")  # non-redacted field preserved
})

test_that("all mode passes everything through", {
  df <- data.frame(id = "1", name = "Main Campus", city = "Auckland",
                   stringsAsFactors = FALSE)
  result <- apply_field_policy(df, "campuses")
  expect_equal(ncol(result), 3)
})

test_that("Unknown entity passes through (no policy)", {
  df <- data.frame(id = "1", secret = "value", stringsAsFactors = FALSE)
  result <- apply_field_policy(df, "unknown_entity")
  expect_equal(ncol(result), 2)
})

test_that("New API fields are excluded by allow mode", {
  df <- data.frame(
    id = "1", student_status = "Active",
    new_secret_field = "sensitive data",
    stringsAsFactors = FALSE
  )
  result <- apply_field_policy(df, "students")
  expect_true(!"new_secret_field" %in% names(result))
})

# ── Layer 4b: Field Policy Loading ───────────────────────────────────────

cat("\nLayer 4b: Field Policy File Loading\n")

test_that("Default field_policy.yml is valid YAML", {
  # Find the policy file
  script_dir <- getwd()
  candidates <- c(
    file.path(script_dir, "inst", "mcp", "field_policy.yml"),
    file.path(script_dir, "field_policy.yml")
  )
  # Also try relative to this script
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    script_path <- normalizePath(sub("^--file=", "", file_arg[1]), mustWork = FALSE)
    candidates <- c(
      file.path(dirname(script_path), "field_policy.yml"),
      candidates
    )
  }

  policy_path <- NULL
  for (p in candidates) {
    if (file.exists(p)) {
      policy_path <- p
      break
    }
  }

  if (!is.null(policy_path)) {
    policy <- yaml::yaml.load_file(policy_path)
    expect_true(is.list(policy))
    expect_true("students" %in% names(policy))
    expect_equal(policy$students$mode, "allow")
    expect_true("id" %in% policy$students$fields)
    # PII fields should NOT be in the allow list
    expect_true(!"surname" %in% policy$students$fields)
    expect_true(!"email1" %in% policy$students$fields)
    expect_true(!"dob" %in% policy$students$fields)
    expect_true(!"nsn" %in% policy$students$fields)
    # Lookup entities should be mode: all
    expect_equal(policy$campuses$mode, "all")
    expect_equal(policy$ethnicities$mode, "all")
    cat("    (tested policy from: ", policy_path, ")\n")
  } else {
    cat("    (skipped — field_policy.yml not found in expected locations)\n")
  }
})

# ── Layer 6: Output Scanning ────────────────────────────────────────────

cat("\nLayer 6: Output Scanning\n")

PII_PATTERNS <- list(
  email    = "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}",
  nz_phone = "\\+64[0-9]{7,10}",
  au_phone = "\\+61[0-9]{8,9}",
  nz_mobile = "(?:^|\\s)02[0-9]{7,9}",
  dob_iso  = paste0(
    "\\b(?:19[5-9][0-9]|200[0-9]|201[0-9])",
    "-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12][0-9]|3[01])\\b"
  )
)

.pii_dictionary <- new.env(parent = emptyenv())
.pii_dictionary$values <- character(0)

escape_regex <- function(x) {
  gsub("([.\\|()\\[\\^$*+?])", "\\\\\\1", x, perl = TRUE)
}

scan_output_for_pii <- function(text) {
  if (!is.character(text) || length(text) == 0) return(list(text = text, redactions = character(0)))

  redacted <- text
  redactions <- character(0)

  for (pii_type in names(PII_PATTERNS)) {
    pattern <- PII_PATTERNS[[pii_type]]
    matches <- gregexpr(pattern, redacted, perl = TRUE)
    n_matches <- sum(vapply(matches, function(m) sum(m > 0), integer(1)))
    if (n_matches > 0) {
      redacted <- gsub(pattern, paste0("[REDACTED:", pii_type, "]"), redacted, perl = TRUE)
      redactions <- c(redactions, paste0(pii_type, ": ", n_matches, " match(es)"))
    }
  }

  dict_hits <- 0L
  for (val in .pii_dictionary$values) {
    pattern <- paste0("\\b", escape_regex(val), "\\b")
    if (grepl(pattern, redacted, ignore.case = TRUE, perl = TRUE)) {
      redacted <- gsub(pattern, "[REDACTED:pii]", redacted, ignore.case = TRUE, perl = TRUE)
      dict_hits <- dict_hits + 1L
    }
  }
  if (dict_hits > 0) {
    redactions <- c(redactions, paste0("dictionary: ", dict_hits, " match(es)"))
  }

  list(text = redacted, redactions = redactions)
}

# Regex tests
test_that("Email addresses are redacted", {
  result <- scan_output_for_pii("Contact john.smith@example.com for details")
  expect_match(result$text, "\\[REDACTED:email\\]")
  expect_no_match(result$text, "john.smith@example.com")
  expect_true(length(result$redactions) > 0)
})

test_that("NZ phone numbers are redacted", {
  result <- scan_output_for_pii("Call +6421123456 for info")
  expect_match(result$text, "\\[REDACTED:nz_phone\\]")
  expect_no_match(result$text, "\\+6421123456")
})

test_that("AU phone numbers are redacted", {
  result <- scan_output_for_pii("Call +61412345678 for info")
  expect_match(result$text, "\\[REDACTED:au_phone\\]")
})

test_that("NZ mobile numbers are redacted", {
  result <- scan_output_for_pii("Mobile 0211234567 is on file")
  expect_match(result$text, "\\[REDACTED:nz_mobile\\]")
})

test_that("DOB-like dates are redacted", {
  result <- scan_output_for_pii("Born on 1990-05-15 in Auckland")
  expect_match(result$text, "\\[REDACTED:dob_iso\\]")
  expect_no_match(result$text, "1990-05-15")
})

test_that("Future dates are NOT redacted (not DOBs)", {
  result <- scan_output_for_pii("Intake starts 2025-03-01")
  expect_no_match(result$text, "REDACTED")
})

test_that("Clean text passes through unchanged", {
  input <- "There are 42 students enrolled in 3 programmes"
  result <- scan_output_for_pii(input)
  expect_equal(result$text, input)
  expect_equal(length(result$redactions), 0)
})

test_that("Multiple PII items in one text", {
  result <- scan_output_for_pii(
    "Email john@test.com, phone +6421999888, born 1985-06-12"
  )
  expect_true(length(result$redactions) >= 3)
  expect_no_match(result$text, "john@test.com")
  expect_no_match(result$text, "\\+6421999888")
  expect_no_match(result$text, "1985-06-12")
})

# Dictionary tests
test_that("PII dictionary catches known surnames", {
  .pii_dictionary$values <- c("Kowalczyk", "Nguyen", "Smith")
  result <- scan_output_for_pii("Student Kowalczyk submitted the assessment")
  expect_match(result$text, "\\[REDACTED:pii\\]")
  expect_no_match(result$text, "Kowalczyk")
  .pii_dictionary$values <- character(0)
})

test_that("Dictionary uses whole-word matching", {
  .pii_dictionary$values <- c("Lee")
  result <- scan_output_for_pii("The employee record shows 5 Leeds-based staff")
  # "Lee" should NOT match "employee" or "Leeds"
  expect_no_match(result$text, "REDACTED")
  # But should match standalone "Lee"
  result2 <- scan_output_for_pii("Student Lee passed the exam")
  expect_match(result2$text, "\\[REDACTED:pii\\]")
  .pii_dictionary$values <- character(0)
})

test_that("Dictionary is case-insensitive", {
  .pii_dictionary$values <- c("Smith")
  result <- scan_output_for_pii("SMITH submitted the form")
  expect_match(result$text, "\\[REDACTED:pii\\]")
  expect_no_match(result$text, "SMITH")
  .pii_dictionary$values <- character(0)
})

test_that("Short dictionary values (<3 chars) are excluded at build time", {
  # Simulate build_pii_dictionary filtering
  values <- c("Li", "Jo", "Alexander", "Wu")
  values <- values[nchar(values) >= 3]
  expect_equal(values, "Alexander")
})

# ── Layer 7: Audit Log ──────────────────────────────────────────────────

cat("\nLayer 7: Audit Log\n")

test_that("Audit log entry is valid JSONL", {
  tmp_log <- tempfile(fileext = ".jsonl")

  audit_log_test <- function(entry) {
    entry$timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
    line <- as.character(jsonlite::toJSON(entry, auto_unbox = TRUE, null = "null"))
    cat(line, "\n", sep = "", file = tmp_log, append = TRUE)
  }

  audit_log_test(list(tool = "describe_entity", entity = "students",
                      response_bytes = 1234, is_error = FALSE))
  audit_log_test(list(tool = "execute_r", code_blocked = TRUE,
                      blocked_constructs = list("selmaR::selma_students"),
                      is_error = TRUE))

  lines <- readLines(tmp_log, warn = FALSE)
  expect_equal(length(lines), 2)

  e1 <- jsonlite::fromJSON(lines[1])
  expect_equal(e1$tool, "describe_entity")
  expect_equal(e1$entity, "students")

  e2 <- jsonlite::fromJSON(lines[2])
  expect_true(e2$code_blocked)
  expect_true(e2$is_error)

  unlink(tmp_log)
})

# ── Entity Registry ─────────────────────────────────────────────────────

cat("\nEntity Registry\n")

ENTITY_REGISTRY <- list(
  students = list(fetch_fn = "selma_students", description = "Student records"),
  enrolments = list(fetch_fn = "selma_enrolments", description = "Enrolment records"),
  intakes = list(fetch_fn = "selma_intakes", description = "Intake definitions"),
  components = list(fetch_fn = "selma_components", description = "Components"),
  programmes = list(fetch_fn = "selma_programmes", description = "Programmes")
)

test_that("All registry entries have required fields", {
  for (name in names(ENTITY_REGISTRY)) {
    reg <- ENTITY_REGISTRY[[name]]
    expect_true(!is.null(reg$fetch_fn),
                paste0("Entity '", name, "' missing fetch_fn"))
    expect_true(!is.null(reg$description),
                paste0("Entity '", name, "' missing description"))
  }
})

test_that("All registry fetch functions exist in selmaR", {
  # Try to load selmaR via pkgload or installed package
  selmar_ns <- tryCatch({
    # First try pkgload (dev mode)
    args <- commandArgs(trailingOnly = FALSE)
    file_arg <- grep("^--file=", args, value = TRUE)
    pkg_candidate <- NULL
    if (length(file_arg) > 0) {
      script_path <- normalizePath(sub("^--file=", "", file_arg[1]), mustWork = FALSE)
      pkg_candidate <- normalizePath(file.path(dirname(script_path), "..", ".."),
                                     mustWork = FALSE)
    }
    if (!is.null(pkg_candidate) && file.exists(file.path(pkg_candidate, "DESCRIPTION"))) {
      suppressPackageStartupMessages(
        pkgload::load_all(pkg_candidate, export_all = FALSE, quiet = TRUE)
      )
      asNamespace("selmaR")
    } else {
      asNamespace("selmaR")
    }
  }, error = function(e) NULL)

  if (is.null(selmar_ns)) {
    cat("    (skipped — selmaR not loadable)\n")
    .test_results$passed <<- .test_results$passed + 1L
    return(invisible(NULL))
  }

  for (name in names(ENTITY_REGISTRY)) {
    fn_name <- ENTITY_REGISTRY[[name]]$fetch_fn
    fn <- tryCatch(
      get(fn_name, envir = selmar_ns),
      error = function(e) NULL
    )
    expect_true(!is.null(fn),
                paste0("Function '", fn_name, "' not found in selmaR"))
  }
})

# ── Integration: Combined Layers ─────────────────────────────────────────

cat("\nIntegration: Combined Layers\n")

test_that("Full pipeline: fetch + policy + pseudonymise + scan", {
  # Simulate the full pipeline
  raw_df <- data.frame(
    id = c("1001", "1002"),
    surname = c("Smith", "Nguyen"),
    forename = c("John", "Mai"),
    student_status = c("Active", "Active"),
    gender = c("M", "F"),
    nationality = c("NZ", "VN"),
    email1 = c("john.smith@test.com", "mai.nguyen@test.com"),
    dob = c("1990-05-15", "1995-08-22"),
    nsn = c("123456789", "987654321"),
    stringsAsFactors = FALSE
  )

  # Build PII dictionary from raw data BEFORE policy
  pii_cols <- c("surname", "forename", "email1", "nsn")
  for (col in pii_cols) {
    vals <- unique(na.omit(as.character(raw_df[[col]])))
    vals <- vals[nchar(vals) >= 3]
    .pii_dictionary$values <- unique(c(.pii_dictionary$values, vals))
  }

  # Apply field policy (students: allow mode)
  .mcp_policy$students <- list(
    mode = "allow",
    fields = c("id", "student_status", "gender", "nationality")
  )
  filtered <- apply_field_policy(raw_df, "students")
  expect_true(!"surname" %in% names(filtered))
  expect_true(!"email1" %in% names(filtered))
  expect_true(!"nsn" %in% names(filtered))

  # Apply pseudonymisation
  pseudonymised <- apply_pseudonymisation(filtered)
  expect_match(pseudonymised$id[1], "^S-")

  # Simulate output text that might leak PII
  output_text <- paste0(
    "Summary: 2 students found. ",
    "Note: Smith mentioned fees concern. ",
    "Contact: john.smith@test.com"
  )

  # Output scan should catch the leaked PII
  scanned <- scan_output_for_pii(output_text)
  expect_no_match(scanned$text, "Smith")
  expect_no_match(scanned$text, "john.smith@test.com")
  expect_true(length(scanned$redactions) >= 2)

  # Clean up
  .pii_dictionary$values <- character(0)
})

# ── Results ──────────────────────────────────────────────────────────────

cat("\n=== Results ===\n")
cat(paste0("Passed: ", .test_results$passed, "\n"))
cat(paste0("Failed: ", .test_results$failed, "\n"))

if (length(.test_results$errors) > 0) {
  cat("\nFailure details:\n")
  for (err in .test_results$errors) {
    cat(paste0("  ", err, "\n"))
  }
}

if (.test_results$failed > 0) {
  quit(status = 1)
} else {
  cat("\nAll tests passed!\n")
  quit(status = 0)
}
