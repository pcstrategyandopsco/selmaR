#!/usr/bin/env Rscript

# ── selmaR MCP Server ─────────────────────────────────────────────────────
# Model Context Protocol server for querying SELMA student management data.
# Communicates via JSON-RPC 2.0 over stdio (stdin/stdout).
# All diagnostic output goes to stderr; stdout is reserved for MCP protocol.
#
# 7 Defence Layers:
#   1. ID pseudonymisation (session-scoped deterministic hash)
#   2. AST code inspection (blocked packages/functions)
#   3. Input allowlisting (7 tools, no raw API access)
#   4. PII field policy (configurable YAML allowlist)
#   5. Hybrid data access (aggregates only in structured tools)
#   6. Output scanning (regex + PII dictionary)
#   7. Audit logging (JSONL + session report)
#
# Usage:
#   Rscript inst/mcp/server.R
#
# Claude Desktop / Claude Code config:
#   {
#     "mcpServers": {
#       "selmaR": {
#         "command": "Rscript",
#         "args": ["/path/to/selmaR/inst/mcp/server.R"],
#         "cwd": "/path/to/directory/containing/config.yml"
#       }
#     }
#   }

# ── 1. Preamble ───────────────────────────────────────────────────────────

suppressPackageStartupMessages({
  library(jsonlite)
  library(stringr)
  library(yaml)
  library(digest)
})

# Load selmaR: use pkgload::load_all() for dev mode, library() if installed
pkg_root <- Sys.getenv("SELMAR_PKG_DIR", "")
if (nchar(pkg_root) == 0) {
  # Auto-detect: script lives at <pkg>/inst/mcp/server.R
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    script_path <- normalizePath(sub("^--file=", "", file_arg[1]), mustWork = FALSE)
    candidate <- normalizePath(file.path(dirname(script_path), "..", ".."),
                               mustWork = FALSE)
    if (file.exists(file.path(candidate, "DESCRIPTION"))) {
      pkg_root <- candidate
    }
  }
}

if (nchar(pkg_root) > 0 && file.exists(file.path(pkg_root, "DESCRIPTION"))) {
  suppressPackageStartupMessages(
    pkgload::load_all(pkg_root, export_all = FALSE, quiet = TRUE)
  )
} else {
  suppressPackageStartupMessages(library(selmaR))
}

# Redirect all cli output to stderr so it doesn't corrupt the MCP protocol
options(
  cli.default_handler = function(msg) {
    cat(conditionMessage(msg), file = stderr())
  }
)

mcp_log <- function(...) {
  cat(paste0("[selmaR] ", ..., "\n"), file = stderr())
}

# Helper: named list that serializes as {} not []
empty_obj <- function() structure(list(), names = character(0))

SERVER_VERSION <- "0.1.0"

# ── 2. Output Directory ───────────────────────────────────────────────────

MCP_OUTPUT_DIR <- Sys.getenv("SELMAR_OUTPUT_DIR", "")
if (nchar(MCP_OUTPUT_DIR) == 0) {
  base_dir <- if (nchar(pkg_root) > 0 && dir.exists(pkg_root)) {
    pkg_root
  } else if (getwd() != "/") {
    getwd()
  } else {
    Sys.getenv("HOME", tempdir())
  }
  MCP_OUTPUT_DIR <- file.path(base_dir, "selmaR_output")
}
MCP_OUTPUT_DIR <- normalizePath(MCP_OUTPUT_DIR, mustWork = FALSE)
if (!dir.exists(MCP_OUTPUT_DIR)) {
  ok <- dir.create(MCP_OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)
  if (!ok) {
    mcp_log("WARNING: Could not create output dir: ", MCP_OUTPUT_DIR)
    MCP_OUTPUT_DIR <- file.path(tempdir(), "selmaR_output")
    dir.create(MCP_OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)
    mcp_log("Using fallback output dir: ", MCP_OUTPUT_DIR)
  }
}
mcp_log("Output directory: ", MCP_OUTPUT_DIR)

# ── 3. MCP Config ─────────────────────────────────────────────────────────

.mcp_config <- list(
  expose_real_ids = FALSE
)

# Check for MCP config in config.yml
tryCatch({
  cfg_path <- if (file.exists("config.yml")) {
    "config.yml"
  } else if (nchar(pkg_root) > 0 && file.exists(file.path(pkg_root, "config.yml"))) {
    file.path(pkg_root, "config.yml")
  } else {
    NULL
  }
  if (!is.null(cfg_path)) {
    cfg <- yaml::yaml.load_file(cfg_path)
    if (!is.null(cfg$default$mcp$expose_real_ids)) {
      .mcp_config$expose_real_ids <- isTRUE(cfg$default$mcp$expose_real_ids)
    }
  }
}, error = function(e) {
  mcp_log("Config read warning: ", conditionMessage(e))
})

# ── 3b. SELMA Connection ──────────────────────────────────────────────────
# Connect at startup using config.yml (cwd first, then package root) or
# SELMA_* environment variables. Non-fatal — tools error until connected.
tryCatch({
  connect_cfg <- if (file.exists("config.yml")) {
    "config.yml"
  } else if (nchar(pkg_root) > 0 && file.exists(file.path(pkg_root, "config.yml"))) {
    file.path(pkg_root, "config.yml")
  } else {
    NULL
  }
  selmaR::selma_connect(config_file = connect_cfg)
  mcp_log("SELMA connection established (",
          selmaR::selma_get_connection()$api_version, ")")
}, error = function(e) {
  mcp_log("SELMA connection not established at startup: ", conditionMessage(e))
  mcp_log("Set credentials in config.yml (cwd) or SELMA_* environment variables.")
})

# ── 4. Security Layer 1: ID Pseudonymisation ──────────────────────────────

.mcp_seed <- as.character(sample.int(1e9, 1))

# Column name patterns → prefix for pseudonymised IDs
# IMPORTANT: The same underlying ID must always get the same prefix regardless
# of which entity it appears in, otherwise cross-entity joins break.
# The "id" column is ambiguous (could be student, enrolment, contact, etc.)
# so we handle it per-entity in apply_pseudonymisation().
ID_COLUMN_PATTERNS <- list(
  list(pattern = "^(student_id|studentid)$",             prefix = "S"),
  list(pattern = "^nsn$",                                prefix = "N"),
  list(pattern = "^(contact_id|contactid)$",             prefix = "C"),
  list(pattern = "^(enrolment_id|enrolid|enrol_id)$",    prefix = "E"),
  list(pattern = "^(intake_id|intakeid)$",               prefix = "I"),
  list(pattern = "^(compenrid)$",                        prefix = "CE"),
  list(pattern = "^(compid)$",                           prefix = "CP"),
  list(pattern = "^(progid|prog_id|interested_progid)$", prefix = "P"),
  list(pattern = "^(campus_id|campusid)$",               prefix = "CA"),
  list(pattern = "^(strand_id)$",                        prefix = "ST"),
  list(pattern = "^(orgid)$",                            prefix = "O"),
  list(pattern = "^(parentid)$",                         prefix = "E"),
  list(pattern = "^(interested_intakeid)$",              prefix = "I"),
  list(pattern = "^(addressid)$",                        prefix = "A"),
  list(pattern = "^(noteid)$",                           prefix = "NT"),
  list(pattern = "^(enrolmentid)$",                      prefix = "E")
)

# Maps entity name -> prefix for the generic "id" column
ENTITY_ID_PREFIX <- c(
  students = "S", enrolments = "E", contacts = "C",
  intakes = "I", programmes = "P", components = "CE",
  organisations = "O", classes = "CL", campuses = "CA",
  addresses = "A", notes = "NT"
)

pseudonymise_id <- function(id, prefix = "S") {
  if (is.na(id) || id == "") return(id)
  hash <- substr(digest::digest(paste0(.mcp_seed, id), algo = "md5"), 1, 8)
  paste0(prefix, "-", hash)
}

pseudonymise_column <- function(values, prefix = "S") {
  vapply(values, function(v) pseudonymise_id(v, prefix), character(1),
         USE.NAMES = FALSE)
}

apply_pseudonymisation <- function(df, entity_name = NULL) {
  if (.mcp_config$expose_real_ids) return(df)
  for (col in names(df)) {
    col_lower <- tolower(col)

    # Handle the ambiguous "id" column using entity context
    if (col_lower == "id") {
      prefix <- if (!is.null(entity_name) && entity_name %in% names(ENTITY_ID_PREFIX)) {
        ENTITY_ID_PREFIX[[entity_name]]
      } else {
        "S"  # fallback
      }
      df[[col]] <- pseudonymise_column(as.character(df[[col]]), prefix)
      next
    }

    for (pat in ID_COLUMN_PATTERNS) {
      if (grepl(pat$pattern, col_lower)) {
        df[[col]] <- pseudonymise_column(as.character(df[[col]]), pat$prefix)
        break
      }
    }
  }
  df
}

# ── 5. Security Layer 2: AST Code Inspection ─────────────────────────────

BLOCKED_PACKAGES <- c("selmaR", "httr", "httr2", "curl", "jsonlite", "config")

BLOCKED_FUNCTIONS <- c(
  # Metaprogramming / indirect dispatch
  "eval", "evalq", "do.call", "get", "mget", "exists",
  "match.fun", "getExportedValue", "loadNamespace", "requireNamespace",
  # Environment / credential access
  "Sys.getenv", "Sys.setenv",
  # Shell execution
  "system", "system2", "shell",
  # File I/O
  "readLines", "scan", "file", "readRDS", "writeLines",
  "write.csv", "write.csv2", "saveRDS",
  # Network
  "download.file", "url", "socketConnection"
)

check_code_safety <- function(code) {
  expr <- tryCatch(parse(text = code), error = function(e) NULL)
  if (is.null(expr)) return(list(safe = TRUE))  # syntax error — will fail at eval

  blocked <- character(0)

  walk <- function(node) {
    if (is.call(node)) {
      fn <- node[[1]]
      # Detect :: and ::: with blocked packages
      if (is.call(fn) && length(fn) >= 3 &&
          as.character(fn[[1]]) %in% c("::", ":::")) {
        pkg <- as.character(fn[[2]])
        if (pkg %in% BLOCKED_PACKAGES) {
          blocked <<- c(blocked, paste0(pkg, "::", as.character(fn[[3]])))
        }
      }
      # Detect blocked function calls
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

# ── 6. Security Layer 4: PII Field Policy ────────────────────────────────

.mcp_policy <- list()

load_field_policy <- function() {
  # Resolution order: env var > cwd > package default
  policy_path <- Sys.getenv("SELMAR_FIELD_POLICY", "")

  if (nchar(policy_path) == 0 || !file.exists(policy_path)) {
    policy_path <- "field_policy.yml"
  }
  if (!file.exists(policy_path) && nchar(pkg_root) > 0) {
    policy_path <- file.path(pkg_root, "inst", "mcp", "field_policy.yml")
  }
  if (!file.exists(policy_path)) {
    # Try system file from installed package
    policy_path <- system.file("mcp", "field_policy.yml", package = "selmaR")
  }

  if (nchar(policy_path) > 0 && file.exists(policy_path)) {
    .mcp_policy <<- yaml::yaml.load_file(policy_path)
    mcp_log("Field policy loaded from: ", policy_path)
    mcp_log("Entities configured: ", length(.mcp_policy))
  } else {
    mcp_log("WARNING: No field policy found. All fields will be exposed.")
  }
}

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

# ── 7. Security Layer 6: Output Scanning ─────────────────────────────────

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

# PII dictionary — built from fetched entity data
.pii_dictionary <- new.env(parent = emptyenv())
.pii_dictionary$values <- character(0)

PII_DICTIONARY_SOURCES <- list(
  # Both v2 and v3 column names — intersect() picks whichever exists in data
  students = c(
    # v2
    "surname", "forename", "preferredname",
    "email1", "email2", "mobilephone", "homephone", "workphone", "nsn",
    # v3
    "last_name", "first_name", "preferred_name",
    "email_primary", "email_secondary", "phone_mobile", "phone_home",
    "phone_work", "email_school", "national_student_number", "user_name"
  ),
  contacts = c(
    # v2
    "surname", "forename", "email", "mobilephone", "workphone",
    # v3
    "last_name", "first_name", "email", "phone_mobile", "phone_work"
  )
)

build_pii_dictionary <- function(df, entity_name) {
  cols <- PII_DICTIONARY_SOURCES[[entity_name]]
  if (is.null(cols)) return(invisible(NULL))

  for (col in intersect(cols, names(df))) {
    values <- unique(na.omit(as.character(df[[col]])))
    # Filter out short/common values to avoid false positives
    values <- values[nchar(values) >= 3]
    .pii_dictionary$values <- unique(c(.pii_dictionary$values, values))
  }
}

escape_regex <- function(x) {
  gsub("([.\\|()\\[\\^$*+?])", "\\\\\\1", x, perl = TRUE)
}

scan_output_for_pii <- function(text) {
  if (!is.character(text) || length(text) == 0) return(list(text = text, redactions = character(0)))

  redacted <- text
  redactions <- character(0)

  # Regex pattern scan
  for (pii_type in names(PII_PATTERNS)) {
    pattern <- PII_PATTERNS[[pii_type]]
    matches <- gregexpr(pattern, redacted, perl = TRUE)
    n_matches <- sum(vapply(matches, function(m) sum(m > 0), integer(1)))
    if (n_matches > 0) {
      redacted <- gsub(pattern, paste0("[REDACTED:", pii_type, "]"), redacted, perl = TRUE)
      redactions <- c(redactions, paste0(pii_type, ": ", n_matches, " match(es)"))
    }
  }

  # PII dictionary scan (case-insensitive whole-word matching)
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

# ── 8. Security Layer 7: Audit Log ───────────────────────────────────────

.audit <- new.env(parent = emptyenv())
.audit$session_start <- Sys.time()
.audit$log_path <- file.path(MCP_OUTPUT_DIR, "selma_mcp_audit.jsonl")
.audit$output_dir <- MCP_OUTPUT_DIR

audit_log <- function(tool, arguments = list(), response_bytes = 0L,
                      redactions = character(0), code_blocked = FALSE,
                      blocked_constructs = character(0), is_error = FALSE,
                      entity = NA_character_) {
  entry <- list(
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    tool = tool,
    arguments = arguments,
    response_bytes = response_bytes,
    redactions_applied = if (length(redactions) > 0) redactions else list(),
    code_blocked = code_blocked,
    is_error = is_error
  )
  if (!is.na(entity)) entry$entity <- entity
  if (code_blocked && length(blocked_constructs) > 0) {
    entry$blocked_constructs <- blocked_constructs
  }
  line <- as.character(jsonlite::toJSON(entry, auto_unbox = TRUE, null = "null"))
  tryCatch(
    cat(line, "\n", sep = "", file = .audit$log_path, append = TRUE),
    error = function(e) mcp_log("Audit log write failed: ", conditionMessage(e))
  )
}

# ── 9. Session Report (generated on exit) ─────────────────────────────────

generate_session_report <- function() {
  tryCatch({
    if (!file.exists(.audit$log_path)) {
      mcp_log("No audit log found, skipping session report.")
      return(invisible(NULL))
    }

    log_lines <- readLines(.audit$log_path, warn = FALSE)
    if (length(log_lines) == 0) {
      mcp_log("Empty audit log, skipping session report.")
      return(invisible(NULL))
    }

    log_entries <- lapply(log_lines, function(l) {
      tryCatch(jsonlite::fromJSON(l, simplifyVector = FALSE), error = function(e) NULL)
    })
    log_entries <- Filter(Negate(is.null), log_entries)

    n_calls <- length(log_entries)
    n_blocked <- sum(vapply(log_entries, function(e) isTRUE(e$code_blocked), logical(1)))
    n_errors <- sum(vapply(log_entries, function(e) isTRUE(e$is_error), logical(1)))
    entities_accessed <- unique(na.omit(vapply(log_entries, function(e) {
      if (!is.null(e$entity)) e$entity else NA_character_
    }, character(1))))
    all_redactions <- unlist(lapply(log_entries, function(e) e$redactions_applied))
    duration <- difftime(Sys.time(), .audit$session_start, units = "mins")

    # Build HTML report
    tool_rows <- vapply(log_entries, function(e) {
      paste0(
        "    <tr><td>", htmltools_esc(e$timestamp %||% ""),
        "</td><td>", htmltools_esc(e$tool %||% ""),
        "</td><td>", e$response_bytes %||% 0,
        "</td><td>", if (isTRUE(e$is_error)) "Yes" else "No",
        "</td></tr>"
      )
    }, character(1))

    html <- paste0(
      "<!DOCTYPE html><html><head><meta charset='utf-8'>",
      "<title>selmaR MCP Session Report</title>",
      "<style>body{font-family:system-ui,sans-serif;margin:2rem;background:#fafafa}",
      "h1{color:#333}h2{color:#555;border-bottom:1px solid #ddd;padding-bottom:.3rem}",
      "table{border-collapse:collapse;width:100%}th,td{text-align:left;padding:.4rem .8rem;",
      "border:1px solid #ddd}th{background:#f0f0f0}.warn{color:#c00;font-weight:bold}",
      ".meta{color:#666;font-size:.85rem}</style></head><body>",
      "<h1>selmaR MCP Session Report</h1>",
      "<h2>Session</h2>",
      "<p>Start: ", format(.audit$session_start, "%Y-%m-%d %H:%M:%S"), "<br>",
      "Duration: ", round(as.numeric(duration), 1), " minutes<br>",
      "Server version: ", SERVER_VERSION, "</p>",
      "<h2>Security</h2>",
      "<p>Field policy: ", length(.mcp_policy), " entities configured<br>",
      "ID pseudonymisation: ", if (.mcp_config$expose_real_ids) "<span class='warn'>OFF (real IDs exposed)</span>" else "ON",
      "</p>",
      "<h2>Tool Calls (", n_calls, ")</h2>",
      "<table><tr><th>Timestamp</th><th>Tool</th><th>Response bytes</th><th>Error</th></tr>",
      paste(tool_rows, collapse = "\n"),
      "</table>",
      "<h2>Entities Accessed</h2>",
      "<p>", if (length(entities_accessed) > 0) paste(entities_accessed, collapse = ", ") else "None", "</p>",
      "<h2>Blocked Attempts</h2>",
      "<p>", n_blocked, " code execution(s) blocked</p>",
      "<h2>PII Redactions</h2>",
      "<p>", if (length(all_redactions) > 0) paste(all_redactions, collapse = "<br>") else "None", "</p>",
      "<p class='meta'>Generated by selmaR MCP server v", SERVER_VERSION, "</p>",
      "</body></html>"
    )

    report_path <- file.path(
      .audit$output_dir,
      paste0("selma_mcp_session_",
             format(.audit$session_start, "%Y%m%d_%H%M%S"),
             ".html")
    )
    writeLines(html, report_path)
    mcp_log("Session summary written to: ", report_path)
    mcp_log(n_calls, " tool calls | ",
            length(entities_accessed), " entities accessed | ",
            n_blocked, " blocked | ",
            length(all_redactions), " redactions")
  }, error = function(e) {
    mcp_log("Session report generation failed: ", conditionMessage(e))
  })
}

# Minimal HTML escaping
htmltools_esc <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("'", "&#39;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

# ── 10. Entity Registry ──────────────────────────────────────────────────

ENTITY_REGISTRY <- list(
  students = list(
    description = "Student records (demographics, status, visa, nationality)",
    fetch_fn = "selma_students",
    endpoint = "students"
  ),
  enrolments = list(
    description = "Enrolment records linking students to intakes (status, dates, funding)",
    fetch_fn = "selma_enrolments",
    endpoint = "enrolments"
  ),
  intakes = list(
    description = "Intake/cohort definitions (programme, dates, capacity)",
    fetch_fn = "selma_intakes",
    endpoint = "intakes"
  ),
  components = list(
    description = "Enrolment components — individual course units (EFTS, status, dates)",
    fetch_fn = "selma_components",
    endpoint = "enrolment_components"
  ),
  programmes = list(
    description = "Programme/qualification definitions (level, EFTS, type)",
    fetch_fn = "selma_programmes",
    endpoint = "programmes"
  ),
  contacts = list(
    description = "External contact records (agents, employers)",
    fetch_fn = "selma_contacts",
    endpoint = "contacts"
  ),
  addresses = list(
    description = "Student address records (city, region, country, postcode)",
    fetch_fn = "selma_addresses",
    endpoint = "addresses"
  ),
  notes = list(
    description = "Student notes and events (type, area, confidentiality)",
    fetch_fn = "selma_notes",
    endpoint = "notes"
  ),
  organisations = list(
    description = "Organisation records (type, country, registration)",
    fetch_fn = "selma_organisations",
    endpoint = "organisations"
  ),
  classes = list(
    description = "Class/teaching group records (dates, capacity, campus)",
    fetch_fn = "selma_classes",
    endpoint = "classes"
  ),
  campuses = list(
    description = "Campus/location definitions",
    fetch_fn = "selma_campuses",
    endpoint = "campuses"
  ),
  ethnicities = list(
    description = "Ethnicity lookup codes",
    fetch_fn = "selma_ethnicities",
    endpoint = "ethnicities"
  ),
  countries = list(
    description = "Country lookup codes",
    fetch_fn = "selma_countries",
    endpoint = "countries"
  ),
  genders = list(
    description = "Gender lookup codes",
    fetch_fn = "selma_genders",
    endpoint = "genders"
  ),
  titles = list(
    description = "Title lookup codes (Mr, Mrs, etc.)",
    fetch_fn = "selma_titles",
    endpoint = "titles"
  ),
  events = list(
    description = "Event records (v3 only) — link notes/tasks/emails to students, enrolments, or intakes",
    fetch_fn = "selma_events",
    endpoint = "events"
  ),
  component_grades = list(
    description = "Component grade/attempt records (v3 only) — assessment attempts against enrolment components",
    fetch_fn = "selma_component_grades",
    endpoint = "enrolment_component_grades"
  )
)

# ── 11. Entity Cache ─────────────────────────────────────────────────────

.entity_cache <- new.env(parent = emptyenv())

get_cached_entity <- function(entity_name) {
  if (is.null(ENTITY_REGISTRY[[entity_name]])) {
    stop("Unknown entity: ", entity_name)
  }

  # Return cached version if available
  if (exists(entity_name, envir = .entity_cache)) {
    return(get(entity_name, envir = .entity_cache))
  }

  # Fetch via selmaR
  fetch_fn_name <- ENTITY_REGISTRY[[entity_name]]$fetch_fn
  fetch_fn <- get(fetch_fn_name, envir = asNamespace("selmaR"))

  mcp_log("Fetching entity: ", entity_name, " via ", fetch_fn_name, "()")
  raw_df <- suppressMessages(fetch_fn())

  # Build PII dictionary BEFORE field policy strips the data
  build_pii_dictionary(raw_df, entity_name)

  # Apply field policy
  filtered_df <- apply_field_policy(raw_df, entity_name)

  # Apply pseudonymisation (entity-aware for "id" column)
  filtered_df <- apply_pseudonymisation(filtered_df, entity_name)

  # Cache the filtered result
  assign(entity_name, filtered_df, envir = .entity_cache)

  mcp_log("Cached entity: ", entity_name, " (", nrow(filtered_df), " rows x ",
          ncol(filtered_df), " cols)")

  filtered_df
}

# ── 12. Column Summary Helper ────────────────────────────────────────────

summarize_column <- function(x, col_name) {
  n_missing <- sum(is.na(x))
  info <- list(column = col_name, type = class(x)[1], n_missing = n_missing)

  if (is.numeric(x)) {
    vals <- x[!is.na(x)]
    if (length(vals) > 0) {
      info$min <- round(min(vals), 4)
      info$max <- round(max(vals), 4)
      info$mean <- round(mean(vals), 4)
    }
  } else if (is.character(x) || is.factor(x)) {
    vals <- as.character(x[!is.na(x)])
    info$n_unique <- length(unique(vals))
    if (length(vals) > 0) {
      tbl <- sort(table(vals), decreasing = TRUE)
      top_n <- min(5, length(tbl))
      top_vals <- utils::head(tbl, top_n)
      info$top_values <- paste(
        paste0(names(top_vals), " (", as.integer(top_vals), ")"),
        collapse = ", "
      )
    }
  } else if (is.logical(x)) {
    info$n_true <- sum(x, na.rm = TRUE)
    info$n_false <- sum(!x, na.rm = TRUE)
  } else if (inherits(x, "Date") || inherits(x, "POSIXt")) {
    vals <- x[!is.na(x)]
    if (length(vals) > 0) {
      info$min <- as.character(min(vals))
      info$max <- as.character(max(vals))
    }
  }

  info
}

# ── 13. JSON & Response Helpers ──────────────────────────────────────────

to_json <- function(x) {
  jsonlite::toJSON(x, auto_unbox = TRUE, POSIXt = "ISO8601", null = "null",
                   na = "null", dataframe = "rows", pretty = FALSE)
}

MAX_RESULT_BYTES <- 800000L  # ~800KB safety limit

mcp_text <- function(text, audience = NULL) {
  content <- list(type = "text", text = text)
  if (!is.null(audience)) {
    content$annotations <- list(audience = audience)
  }
  content
}

mcp_result <- function(contents, is_error = FALSE) {
  if (!is.list(contents[[1]])) {
    contents <- list(contents)
  }
  result <- list(content = contents, isError = is_error)
  # Guard: check serialized size and truncate text if needed
  json_size <- nchar(as.character(to_json(result)), type = "bytes")
  if (json_size > MAX_RESULT_BYTES) {
    for (i in seq_along(result$content)) {
      if (result$content[[i]]$type == "text") {
        text <- result$content[[i]]$text
        keep_bytes <- MAX_RESULT_BYTES - 500L
        text <- substr(text, 1, keep_bytes)
        text <- paste0(
          text,
          "\n\n... [TRUNCATED: response exceeded size limit. ",
          "Use head()/filter() to narrow results in execute_r.]"
        )
        result$content[[i]]$text <- text
        break
      }
    }
  }
  result
}

# Apply output scanning to a result before returning
scan_result <- function(result, tool_name, extra_audit = list()) {
  all_redactions <- character(0)
  total_bytes <- 0L

  for (i in seq_along(result$content)) {
    if (result$content[[i]]$type == "text") {
      scan <- scan_output_for_pii(result$content[[i]]$text)
      result$content[[i]]$text <- scan$text
      all_redactions <- c(all_redactions, scan$redactions)
      total_bytes <- total_bytes + nchar(scan$text, type = "bytes")
    }
  }

  audit_args <- c(
    list(
      tool = tool_name,
      response_bytes = total_bytes,
      redactions = all_redactions,
      is_error = isTRUE(result$isError)
    ),
    extra_audit
  )
  do.call(audit_log, audit_args)

  result
}

# ── 14. Tool Definitions ─────────────────────────────────────────────────

mcp_tools <- list(
  list(
    name = "auth_status",
    description = "Check connection and field policy status.",
    inputSchema = list(
      type = "object",
      properties = empty_obj(),
      required = list()
    )
  ),
  list(
    name = "list_entities",
    description = "List all available SELMA entity types with descriptions.",
    inputSchema = list(
      type = "object",
      properties = empty_obj(),
      required = list()
    )
  ),
  list(
    name = "search_entities",
    description = "Search available entity types by keyword (case-insensitive, matches name and description).",
    inputSchema = list(
      type = "object",
      properties = list(
        keyword = list(type = "string", description = "Search keyword")
      ),
      required = list("keyword")
    )
  ),
  list(
    name = "describe_entity",
    description = paste0(
      "Get per-column summary statistics for an entity. ",
      "Returns aggregates only (counts, distributions, ranges) — never individual rows."
    ),
    inputSchema = list(
      type = "object",
      properties = list(
        entity = list(type = "string", description = "Entity name (e.g. 'students', 'enrolments')")
      ),
      required = list("entity")
    )
  ),
  list(
    name = "get_entity_summary",
    description = paste0(
      "Get filtered/grouped aggregate statistics for an entity. ",
      "Returns counts and means — never individual rows."
    ),
    inputSchema = list(
      type = "object",
      properties = list(
        entity = list(type = "string", description = "Entity name (e.g. 'students', 'enrolments')"),
        filter_by = list(
          type = "object",
          description = "Column-value pairs to filter by (e.g. {\"enrstatus\": \"C\"})",
          additionalProperties = TRUE
        ),
        group_by = list(
          type = "array",
          items = list(type = "string"),
          description = "Column(s) to group by for aggregated stats"
        )
      ),
      required = list("entity")
    )
  ),
  list(
    name = "get_efts_report",
    description = paste0(
      "Generate EFTS (Equivalent Full-Time Student) funding report. ",
      "Returns aggregate funding totals by source and category — no PII."
    ),
    inputSchema = list(
      type = "object",
      properties = list(
        year = list(type = "integer", description = "Calendar year for the report (default: current year)"),
        include_international = list(type = "boolean",
                                     description = "Include international fee-paying (default: false)")
      ),
      required = list()
    )
  ),
  list(
    name = "execute_r",
    description = paste0(
      "Execute R code in a sandboxed persistent workspace. ",
      "Available: dplyr, tidyr, ggplot2, lubridate, scales. ",
      "Use selma_students(), selma_enrolments(), etc. to load policy-filtered data. ",
      "Variables persist between calls. 60-second compute timeout (data loading is separate). ",
      "Code is inspected before execution — namespace access (::) and I/O functions are blocked."
    ),
    inputSchema = list(
      type = "object",
      properties = list(
        code = list(type = "string", description = "R code to execute")
      ),
      required = list("code")
    )
  )
)

# ── 15. Tool Handlers ────────────────────────────────────────────────────

handle_auth_status <- function(args) {
  # Check if we have a stored connection
  has_con <- tryCatch({
    selmaR::selma_get_connection()
    TRUE
  }, error = function(e) FALSE)

  con_info <- if (has_con) {
    con <- selmaR::selma_get_connection()
    list(
      authenticated = TRUE,
      base_url = con$base_url,
      message = paste0("Connected to ", con$base_url)
    )
  } else {
    list(
      authenticated = FALSE,
      message = "Not authenticated. Configure config.yml in the working directory."
    )
  }

  con_info$field_policy_entities <- length(.mcp_policy)
  con_info$pseudonymisation <- if (.mcp_config$expose_real_ids) "OFF (real IDs)" else "ON"
  con_info$output_dir <- MCP_OUTPUT_DIR

  text <- as.character(to_json(con_info))
  result <- mcp_result(list(mcp_text(text)))
  scan_result(result, "auth_status")
}

handle_list_entities <- function(args) {
  entries <- lapply(names(ENTITY_REGISTRY), function(name) {
    reg <- ENTITY_REGISTRY[[name]]
    policy <- .mcp_policy[[name]]
    policy_mode <- if (!is.null(policy)) policy$mode else "none"
    n_fields <- if (!is.null(policy$fields)) length(policy$fields) else NA
    list(
      entity = name,
      description = reg$description,
      policy_mode = policy_mode,
      policy_fields = n_fields
    )
  })

  text <- paste0(
    "Available entities (", length(entries), "):\n\n",
    as.character(to_json(entries))
  )
  result <- mcp_result(list(mcp_text(text)))
  scan_result(result, "list_entities")
}

handle_search_entities <- function(args) {
  keyword <- args$keyword
  if (is.null(keyword) || keyword == "") {
    return(scan_result(
      mcp_result(list(mcp_text("Error: 'keyword' parameter is required.")), is_error = TRUE),
      "search_entities"
    ))
  }

  pattern <- tolower(keyword)
  matches <- lapply(names(ENTITY_REGISTRY), function(name) {
    reg <- ENTITY_REGISTRY[[name]]
    if (grepl(pattern, tolower(name), fixed = TRUE) ||
        grepl(pattern, tolower(reg$description), fixed = TRUE)) {
      list(entity = name, description = reg$description)
    } else {
      NULL
    }
  })
  matches <- Filter(Negate(is.null), matches)

  if (length(matches) == 0) {
    text <- paste0("No entities found matching '", keyword, "'.")
  } else {
    text <- paste0(
      "Found ", length(matches), " entities matching '", keyword, "':\n\n",
      as.character(to_json(matches))
    )
  }
  result <- mcp_result(list(mcp_text(text)))
  scan_result(result, "search_entities")
}

handle_describe_entity <- function(args) {
  entity <- args$entity
  if (is.null(entity) || entity == "") {
    return(scan_result(
      mcp_result(list(mcp_text("Error: 'entity' parameter is required.")), is_error = TRUE),
      "describe_entity"
    ))
  }
  if (is.null(ENTITY_REGISTRY[[entity]])) {
    return(scan_result(
      mcp_result(list(mcp_text(paste0(
        "Error: Unknown entity '", entity, "'. Use list_entities to see available types."
      ))), is_error = TRUE),
      "describe_entity"
    ))
  }

  ds <- get_cached_entity(entity)

  col_summaries <- lapply(names(ds), function(cn) {
    summarize_column(ds[[cn]], cn)
  })

  text <- paste0(
    "Entity: ", entity, "\n",
    "Rows: ", format(nrow(ds), big.mark = ","), "\n",
    "Columns: ", ncol(ds),
    " (policy: ", .mcp_policy[[entity]]$mode %||% "none", ")\n\n",
    "Column summaries:\n", as.character(to_json(col_summaries))
  )
  result <- mcp_result(list(mcp_text(text)))
  scan_result(result, "describe_entity", list(entity = entity))
}

handle_get_entity_summary <- function(args) {
  entity <- args$entity
  if (is.null(entity) || entity == "") {
    return(scan_result(
      mcp_result(list(mcp_text("Error: 'entity' parameter is required.")), is_error = TRUE),
      "get_entity_summary"
    ))
  }
  if (is.null(ENTITY_REGISTRY[[entity]])) {
    return(scan_result(
      mcp_result(list(mcp_text(paste0(
        "Error: Unknown entity '", entity, "'. Use list_entities to see available types."
      ))), is_error = TRUE),
      "get_entity_summary"
    ))
  }

  ds <- get_cached_entity(entity)

  # Apply filters
  filter_by <- args$filter_by
  if (!is.null(filter_by) && length(filter_by) > 0) {
    for (col_name in names(filter_by)) {
      if (col_name %in% names(ds)) {
        filter_val <- filter_by[[col_name]]
        ds <- ds[ds[[col_name]] == filter_val & !is.na(ds[[col_name]]), , drop = FALSE]
      }
    }
  }

  # Group by
  group_by_cols <- args$group_by
  if (!is.null(group_by_cols) && length(group_by_cols) > 0) {
    valid_cols <- group_by_cols[group_by_cols %in% names(ds)]
    if (length(valid_cols) == 0) {
      return(scan_result(
        mcp_result(list(mcp_text(paste0(
          "Error: None of the group_by columns found. Available: ",
          paste(names(ds), collapse = ", ")
        ))), is_error = TRUE),
        "get_entity_summary", list(entity = entity)
      ))
    }

    group_formula <- stats::as.formula(paste("~", paste(valid_cols, collapse = " + ")))
    group_counts <- as.data.frame(stats::xtabs(group_formula, data = ds))
    names(group_counts)[ncol(group_counts)] <- "count"
    group_counts <- group_counts[group_counts$count > 0, , drop = FALSE]
    group_counts <- group_counts[order(-group_counts$count), , drop = FALSE]

    group_stats_text <- paste(utils::capture.output(print(
      utils::head(group_counts, 30)
    )), collapse = "\n")

    text <- paste0(
      "Entity: ", entity, "\n",
      "Rows after filtering: ", format(nrow(ds), big.mark = ","), "\n",
      "Groups (", paste(valid_cols, collapse = ", "), "): ",
      nrow(group_counts), " unique\n\n",
      "Group counts (top 30):\n", group_stats_text
    )

    # Add numeric column means per group
    numeric_cols <- names(ds)[vapply(ds, is.numeric, logical(1))]
    numeric_cols <- setdiff(numeric_cols, valid_cols)
    if (length(numeric_cols) > 0) {
      agg_cols <- utils::head(numeric_cols, 5)
      agg_text <- character(0)
      for (ac in agg_cols) {
        agg <- stats::aggregate(
          ds[[ac]],
          by = ds[valid_cols],
          FUN = function(v) round(mean(v, na.rm = TRUE), 2),
          na.action = NULL
        )
        names(agg)[ncol(agg)] <- paste0("mean_", ac)
        agg_text <- c(agg_text, paste0(
          "\nMean ", ac, " per group:\n",
          paste(utils::capture.output(print(utils::head(agg, 20))), collapse = "\n")
        ))
      }
      text <- paste0(text, paste(agg_text, collapse = "\n"))
    }
  } else {
    # No grouping — per-column summary stats
    col_summaries <- lapply(names(ds), function(cn) {
      summarize_column(ds[[cn]], cn)
    })
    text <- paste0(
      "Entity: ", entity, "\n",
      "Rows: ", format(nrow(ds), big.mark = ","), "\n",
      "Columns: ", ncol(ds), "\n\n",
      "Column summaries:\n", as.character(to_json(col_summaries))
    )
  }

  result <- mcp_result(list(mcp_text(text)))
  scan_result(result, "get_entity_summary", list(entity = entity))
}

handle_get_efts_report <- function(args) {
  year <- args$year
  if (is.null(year)) year <- as.integer(format(Sys.Date(), "%Y"))

  include_intl <- isTRUE(args$include_international)

  # Re-fetch without field policy for the EFTS calculation (internal only)
  raw_components <- tryCatch({
    fetch_fn <- get("selma_components", envir = asNamespace("selmaR"))
    suppressMessages(fetch_fn())
  }, error = function(e) {
    return(scan_result(
      mcp_result(list(mcp_text(paste0("Error fetching components: ", conditionMessage(e)))),
                 is_error = TRUE),
      "get_efts_report"
    ))
  })

  if (inherits(raw_components, "list") && !is.data.frame(raw_components)) {
    return(raw_components)  # error result from tryCatch
  }

  # For v3: EFTS values live in new_zealand_enrolment_component_extensions.
  # Join them in automatically so the user doesn't need to know about this.
  is_v3 <- "enrolment_status" %in% names(raw_components)
  if (is_v3 && !"efts" %in% names(raw_components)) {
    raw_components <- tryCatch({
      nz_ext_fn <- get("selma_get", envir = asNamespace("selmaR"))
      nz_ext <- suppressMessages(nz_ext_fn(endpoint = "new_zealand_enrolment_component_extensions"))
      # nz_ext has: enrolment_component (FK char) + efts + other NZ-specific cols
      dplyr::left_join(
        raw_components,
        dplyr::select(nz_ext, "enrolment_component", "efts",
                      dplyr::any_of(c("funding_category", "payer_type_id"))),
        by = c("id" = "enrolment_component")
      )
    }, error = function(e) {
      # Not a fatal error — selma_efts_report will abort with guidance
      raw_components
    })
  }

  efts <- tryCatch(
    selmaR::selma_efts_report(
      raw_components,
      year = year,
      exclude_international = !include_intl
    ),
    error = function(e) {
      return(scan_result(
        mcp_result(list(mcp_text(paste0("Error computing EFTS: ", conditionMessage(e)))),
                   is_error = TRUE),
        "get_efts_report"
      ))
    }
  )

  if (inherits(efts, "list") && !is.data.frame(efts)) {
    return(efts)  # error result
  }

  text <- paste0(
    "EFTS Report — ", year, "\n",
    if (!include_intl) "(excluding international fee-paying)\n" else "",
    "\n",
    paste(utils::capture.output(print(efts, n = 100)), collapse = "\n")
  )

  result <- mcp_result(list(mcp_text(text)))
  scan_result(result, "get_efts_report", list(entity = "components"))
}

# ── 15b. execute_r Handler ───────────────────────────────────────────────

# Save a ggplot to the output directory and generate an HTML viewer
save_plot <- function(plot_obj, title = NULL) {
  title <- title %||% plot_obj$labels$title %||% "plot"
  slug <- str_replace_all(title, "[^A-Za-z0-9]+", "_")
  slug <- str_replace_all(slug, "^_|_$", "")
  slug <- tolower(substr(slug, 1, 60))
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  base_name <- paste0(slug, "_", timestamp)

  png_path <- file.path(MCP_OUTPUT_DIR, paste0(base_name, ".png"))
  html_path <- file.path(MCP_OUTPUT_DIR, paste0(base_name, ".html"))

  if (requireNamespace("ragg", quietly = TRUE)) {
    ragg::agg_png(png_path, width = 900, height = 600, res = 150,
                  background = "white")
  } else {
    grDevices::png(png_path, width = 900, height = 600, res = 150,
                   bg = "white")
  }
  print(plot_obj)
  grDevices::dev.off()

  mcp_log("Plot saved: ", png_path)

  png_file <- basename(png_path)
  html_title <- if (!is.null(plot_obj$labels$title)) plot_obj$labels$title else title
  html_content <- paste0(
    "<!DOCTYPE html>\n<html>\n<head>\n",
    "  <meta charset='utf-8'>\n",
    "  <title>", htmltools_esc(html_title), "</title>\n",
    "  <style>\n",
    "    body { font-family: system-ui, sans-serif; margin: 2rem; background: #fafafa; }\n",
    "    h1 { color: #333; font-size: 1.4rem; }\n",
    "    img { max-width: 100%; border: 1px solid #ddd; border-radius: 4px; }\n",
    "    .meta { color: #666; font-size: 0.85rem; margin-top: 1rem; }\n",
    "  </style>\n",
    "</head>\n<body>\n",
    "  <h1>", htmltools_esc(html_title), "</h1>\n",
    "  <img src='", png_file, "' alt='", htmltools_esc(html_title), "'>\n",
    "  <p class='meta'>Generated by selmaR MCP server at ",
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "</p>\n",
    "</body>\n</html>"
  )
  writeLines(html_content, html_path)

  list(png_path = png_path, html_path = html_path)
}

handle_execute_r <- function(args) {
  code <- args$code
  if (is.null(code) || code == "") {
    return(scan_result(
      mcp_result(list(mcp_text("Error: 'code' parameter is required.")), is_error = TRUE),
      "execute_r", list(arguments = list(code_length = 0))
    ))
  }

  # Layer 2: AST code inspection
  safety <- check_code_safety(code)
  if (!safety$safe) {
    blocked_msg <- paste0(
      "[BLOCKED] Your code was rejected before execution.\n",
      "Blocked constructs found: ", paste(safety$blocked, collapse = ", "), "\n",
      "Reason: These functions bypass PII controls or access restricted resources.\n",
      "Use the workspace functions instead (e.g. selma_students(), selma_get_entity())."
    )
    audit_log(
      tool = "execute_r",
      arguments = list(code_length = nchar(code)),
      code_blocked = TRUE,
      blocked_constructs = safety$blocked,
      is_error = TRUE
    )
    return(mcp_result(list(mcp_text(blocked_msg)), is_error = TRUE))
  }

  mcp_log("execute_r code: ", substr(code, 1, 200))

  # Pre-warm: detect entity fetch calls in the code and load data BEFORE

  # the execution timeout starts. API fetches can take minutes for large
  # entities and should not be subject to the compute timeout.
  entity_pattern <- "selma_(students|enrolments|intakes|components|programmes|contacts|addresses|notes|organisations|classes|campuses|get_entity)"
  entity_refs <- stringr::str_extract_all(code, entity_pattern)[[1]]
  if (length(entity_refs) > 0) {
    # Map function names to entity names
    fn_to_entity <- c(
      selma_students = "students", selma_enrolments = "enrolments",
      selma_intakes = "intakes", selma_components = "components",
      selma_programmes = "programmes", selma_contacts = "contacts",
      selma_addresses = "addresses", selma_notes = "notes",
      selma_organisations = "organisations", selma_classes = "classes",
      selma_campuses = "campuses"
    )
    entities_needed <- unique(na.omit(fn_to_entity[entity_refs]))
    uncached <- entities_needed[!vapply(entities_needed, function(e) {
      exists(e, envir = .entity_cache)
    }, logical(1))]

    if (length(uncached) > 0) {
      send_notification("notifications/message", list(
        level = "info",
        data = paste0("Loading data from SELMA API: ",
                      paste(uncached, collapse = ", "),
                      ". This may take a moment for large entities...")
      ))
      for (ent in uncached) {
        tryCatch({
          get_cached_entity(ent)
        }, error = function(e) {
          mcp_log("Pre-warm failed for ", ent, ": ", conditionMessage(e))
        })
      }
    }
  }

  .res <- new.env(parent = emptyenv())
  .res$val <- NULL
  .res$output <- character(0)
  .res$messages <- character(0)

  EXEC_TIMEOUT <- 60  # seconds (compute only — data fetching happens above)

  eval_result <- tryCatch(
    withCallingHandlers(
      {
        setTimeLimit(elapsed = EXEC_TIMEOUT, transient = TRUE)
        on.exit(setTimeLimit(elapsed = Inf, transient = TRUE), add = TRUE)
        .res$output <- utils::capture.output({
          .res$val <- eval(parse(text = code), envir = .mcp_workspace)
        })
        "success"
      },
      message = function(m) {
        .res$messages <- c(.res$messages, conditionMessage(m))
        invokeRestart("muffleMessage")
      }
    ),
    error = function(e) {
      setTimeLimit(elapsed = Inf, transient = TRUE)
      msg <- conditionMessage(e)
      if (grepl("time limit|elapsed time", msg, ignore.case = TRUE)) {
        paste0("Execution timed out after ", EXEC_TIMEOUT,
               " seconds. Try filtering data earlier or breaking into smaller steps.")
      } else {
        msg
      }
    }
  )

  if (eval_result != "success") {
    return(scan_result(
      mcp_result(list(mcp_text(paste0("Error executing R code:\n", eval_result))),
                 is_error = TRUE),
      "execute_r", list(arguments = list(code_length = nchar(code)))
    ))
  }

  result_val <- .res$val
  output <- .res$output
  messages <- .res$messages

  # Smart result formatting
  contents <- list()

  is_ggplot <- inherits(result_val, "gg") || inherits(result_val, "ggplot")

  if (is_ggplot) {
    mcp_log("Detected ggplot object, saving plot")
    paths <- tryCatch(save_plot(result_val), error = function(e) {
      mcp_log("save_plot error: ", conditionMessage(e))
      NULL
    })
    if (!is.null(paths)) {
      plot_title <- result_val$labels$title %||% "Untitled plot"
      summary_text <- paste0(
        "Plot saved: ", plot_title, "\n",
        "PNG: ", paths$png_path, "\n",
        "HTML viewer: ", paths$html_path, "\n\n",
        "Ask the user: \"Would you like me to open the chart in your browser?\" ",
        "If yes, call execute_r with: browseURL('", paths$html_path, "')"
      )
      contents <- list(mcp_text(summary_text))
    } else {
      contents <- list(mcp_text("Plot rendering failed."))
    }
  } else if (is.data.frame(result_val)) {
    nr <- nrow(result_val)
    if (nr <= 50) {
      tbl_text <- paste(utils::capture.output(print(result_val, n = nr)), collapse = "\n")
    } else {
      tbl_text <- paste(utils::capture.output(print(utils::head(result_val, 20))), collapse = "\n")
      tbl_text <- paste0(tbl_text, "\n... ", nr - 20, " more rows. Use head()/filter() to narrow.")
    }
    if (length(output) > 0 && any(nchar(output) > 0)) {
      tbl_text <- paste0(paste(output, collapse = "\n"), "\n", tbl_text)
    }
    contents <- list(mcp_text(tbl_text))
  } else if (is.character(result_val) && length(result_val) == 1 &&
             grepl("\\.(html|png|pdf|csv)$", result_val, ignore.case = TRUE)) {
    contents <- list(mcp_text(paste0("File saved: ", result_val)))
  } else {
    if (!is.null(result_val)) {
      val_output <- paste(utils::capture.output(print(result_val)), collapse = "\n")
    } else {
      val_output <- ""
    }
    all_output <- c(output, val_output)
    all_output <- all_output[nchar(all_output) > 0]
    if (length(all_output) == 0) all_output <- "(no visible output)"
    contents <- list(mcp_text(paste(all_output, collapse = "\n")))
  }

  # Prepend captured messages as assistant-facing context
  if (length(messages) > 0) {
    msg_text <- paste(trimws(messages), collapse = "\n")
    contents <- c(list(mcp_text(msg_text, audience = list("assistant"))), contents)
  }

  result <- mcp_result(contents)
  scan_result(result, "execute_r", list(arguments = list(code_length = nchar(code))))
}

# Tool handler dispatch
tool_handlers <- list(
  auth_status = handle_auth_status,
  list_entities = handle_list_entities,
  search_entities = handle_search_entities,
  describe_entity = handle_describe_entity,
  get_entity_summary = handle_get_entity_summary,
  get_efts_report = handle_get_efts_report,
  execute_r = handle_execute_r
)

# ── 16. Workspace Setup ──────────────────────────────────────────────────

.mcp_workspace <- new.env(parent = globalenv())

# Pre-load packages
local({
  suppressPackageStartupMessages({
    require(dplyr, quietly = TRUE)
    require(tidyr, quietly = TRUE)
    require(ggplot2, quietly = TRUE)
    require(lubridate, quietly = TRUE)
    require(scales, quietly = TRUE)
  })
}, envir = .mcp_workspace)

# Expose output directory
.mcp_workspace$output_dir <- MCP_OUTPUT_DIR

# Policy-wrapped entity fetch function
.mcp_workspace$selma_get_entity <- function(entity_name) {
  ds <- get_cached_entity(entity_name)
  nr <- nrow(ds)
  nc <- ncol(ds)
  msg <- paste0("[", entity_name, ": ", format(nr, big.mark = ","), " rows x ", nc, " cols]")
  if (nr > 50000) {
    msg <- paste0(msg, " WARNING: large dataset -- filter early to avoid slow operations")
  }
  message(msg)
  ds
}

# Convenience aliases (shadow the real package functions)
.mcp_workspace$selma_students    <- function() .mcp_workspace$selma_get_entity("students")
.mcp_workspace$selma_enrolments  <- function() .mcp_workspace$selma_get_entity("enrolments")
.mcp_workspace$selma_intakes     <- function() .mcp_workspace$selma_get_entity("intakes")
.mcp_workspace$selma_components  <- function() .mcp_workspace$selma_get_entity("components")
.mcp_workspace$selma_programmes  <- function() .mcp_workspace$selma_get_entity("programmes")
.mcp_workspace$selma_contacts    <- function() .mcp_workspace$selma_get_entity("contacts")
.mcp_workspace$selma_addresses   <- function() .mcp_workspace$selma_get_entity("addresses")
.mcp_workspace$selma_notes       <- function() .mcp_workspace$selma_get_entity("notes")
.mcp_workspace$selma_organisations <- function() .mcp_workspace$selma_get_entity("organisations")
.mcp_workspace$selma_classes     <- function() .mcp_workspace$selma_get_entity("classes")
.mcp_workspace$selma_campuses    <- function() .mcp_workspace$selma_get_entity("campuses")

# Join helpers (operate on already-filtered data)
.mcp_workspace$selma_join_students <- function(enrolments, students) {
  selmaR::selma_join_students(enrolments, students)
}
.mcp_workspace$selma_join_intakes <- function(enrolments, intakes) {
  selmaR::selma_join_intakes(enrolments, intakes)
}
.mcp_workspace$selma_join_components <- function(components, enrolments) {
  selmaR::selma_join_components(components, enrolments)
}
.mcp_workspace$selma_join_programmes <- function(intakes, programmes) {
  selmaR::selma_join_programmes(intakes, programmes)
}

# Pipeline helpers
.mcp_workspace$selma_student_pipeline <- function(enrolments, students, intakes) {
  selmaR::selma_student_pipeline(enrolments, students, intakes)
}
.mcp_workspace$selma_component_pipeline <- function(components, enrolments, students, intakes) {
  selmaR::selma_component_pipeline(components, enrolments, students, intakes)
}

# Inject constants
.mcp_workspace$SELMA_STATUS_CONFIRMED       <- "C"
.mcp_workspace$SELMA_STATUS_COMPLETED       <- "FC"
.mcp_workspace$SELMA_STATUS_INCOMPLETE      <- "FI"
.mcp_workspace$SELMA_STATUS_WITHDRAWN       <- "WR"
.mcp_workspace$SELMA_STATUS_WITHDRAWN_SDR   <- "WS"
.mcp_workspace$SELMA_STATUS_EARLY_WITHDRAWN <- "ER"
.mcp_workspace$SELMA_STATUS_DEFERRED        <- "D"
.mcp_workspace$SELMA_STATUS_CANCELLED       <- "X"
.mcp_workspace$SELMA_STATUS_PENDING         <- "P"
.mcp_workspace$SELMA_FUNDED_STATUSES        <- c("C", "FC", "FI")
.mcp_workspace$SELMA_ALL_FUNDED_STATUSES    <- c("C", "FC", "FI", "WR", "WS")
.mcp_workspace$SELMA_FUNDING_GOVT           <- "01"
.mcp_workspace$SELMA_FUNDING_INTL           <- "02"
.mcp_workspace$SELMA_FUNDING_MPPT           <- "29"
.mcp_workspace$SELMA_FUNDING_YG             <- "31"
.mcp_workspace$SELMA_FUNDING_DQ37           <- "37"

# Chart output helper — safe writeLines to output_dir only
.mcp_workspace$save_chart <- function(html, filename) {
  # Sanitize filename — no directory traversal
  filename <- basename(filename)
  if (!grepl("\\.html$", filename, ignore.case = TRUE)) {
    filename <- paste0(filename, ".html")
  }
  path <- file.path(MCP_OUTPUT_DIR, filename)
  writeLines(html, path)
  message(paste0("[Chart saved: ", path, "]"))
  path
}

# ── 17. Server Instructions ──────────────────────────────────────────────

SERVER_INSTRUCTIONS <- paste0(
  "selmaR MCP server — SELMA student management system data for NZ PTEs/TEOs.\n",
  "Output directory for charts: ", MCP_OUTPUT_DIR, "\n\n",
  "TOOL DISCOVERY\n",
  "This server provides 7 tools: auth_status, list_entities, search_entities,\n",
  "describe_entity, get_entity_summary, get_efts_report, execute_r.\n",
  "If your tool loader uses deferred/paginated discovery, ensure ALL 7 are loaded.\n",
  "Search specifically: \"selmaR execute_r get_entity_summary\" to surface tools\n",
  "that may be missed by a broad category search.\n\n",
  "SECURITY\n",
  "- PII field filtering is active. Some fields (names, emails, phones, DOB) are\n",
  "  redacted per the server's field policy. You will only see policy-allowed columns.\n",
  "- Do NOT use :: namespace access (e.g. selmaR::selma_students). Use the\n",
  "  workspace functions provided. Blocked patterns are rejected before execution.\n",
  "- Never return raw unfiltered data. Always summarise(), count(), or head().\n\n",
  "WORKFLOW\n",
  "1. list_entities — see what data is available\n",
  "2. describe_entity(\"students\") — check columns, row count, distributions\n",
  "3. get_entity_summary with filter_by/group_by — quick aggregate stats\n",
  "4. get_efts_report — EFTS funding analysis (no code needed)\n",
  "5. execute_r — custom dplyr/ggplot2 analysis (data loading is automatic, 60-sec compute timeout)\n\n",
  "API VERSIONS\n",
  "SELMA has two API versions — v2 (legacy) and v3 (current). The server detects\n",
  "the version automatically. Column names differ significantly between versions.\n",
  "Use describe_entity() to see the actual column names for your connected instance.\n\n",
  "SELMA DATA MODEL\n",
  "Students enrol into Intakes (cohorts) via Enrolments.\n",
  "Each Enrolment contains Components (individual course units with EFTS values).\n",
  "Intakes belong to Programmes (qualifications).\n\n",
  "  students --> enrolments --> intakes --> programmes\n",
  "                  |\n",
  "              components\n\n",
  "JOIN KEYS — v2\n",
  "- students.id = enrolments.student_id\n",
  "- enrolments.id = components.enrolid\n",
  "- enrolments.intake_id = intakes.intakeid (integer)\n",
  "- intakes.progid = programmes.progid (integer)\n",
  "- addresses.studentid = students.id\n",
  "- notes.student_id = students.id\n\n",
  "JOIN KEYS — v3 (foreign keys are character strings after IRI stripping)\n",
  "- students.id = as.integer(enrolments.student)\n",
  "- enrolments.id = as.integer(components.enrolment)\n",
  "- as.integer(enrolments.intake) = intakes.id\n",
  "- as.integer(intakes.programme) = programmes.id\n",
  "- as.integer(addresses.student) = students.id\n",
  "- v3 notes (comments) link via events: notes.event -> events.id -> events.student -> students.id\n\n",
  "Use the join helpers — they handle both versions automatically:\n",
  "selma_join_students(), selma_join_intakes(), selma_join_components(),\n",
  "selma_join_programmes(), selma_join_notes(notes, students, events = events),\n",
  "selma_join_addresses(), selma_join_classes(), selma_join_attempts()\n\n",
  "ENTITY FIELDS — v2 column names\n",
  "students: id, status, title, gender, international, citizenship, residency,\n",
  "  residentialstatus, ethnicity1-3, ethnicity, countryofbirth, visatype, feesfree,\n",
  "  prestudyactivity, highpostschoolqual, third_party_id, third_party_id2,\n",
  "  organisation, interested_progid, interested_intakeid\n",
  "enrolments: id, student_id, intake_id, enrstatus, enrstartdate, enrenddate,\n",
  "  enrstatusdate, enrreturntype, enrattendance, completedsuccessfully,\n",
  "  fundingsource, enrcompletiondate, enrcompletiongrade, enrqualcode,\n",
  "  enrwithdrawalreason, enrwithdrawaldate, enrfeesfree, strand_id, third_party_id,\n",
  "  percent_attendance, percent_in_programme, percent_progress\n",
  "components: compenrid, compid, parentid, enrolid, studentid, compenrstartdate,\n",
  "  compenrenddate, compenrduedate, compenrstatus, compenrsource, compenrefts,\n",
  "  compenrfundingcategory, compenrattendance, compenrgrade, compenrcompletioncode,\n",
  "  compenrcompletiondate, compenrextensiondate, compenrwithdrawaldate,\n",
  "  comp_title, comp_credit_fw, comp_level_fw, comp_code, comp_version, comp_type,\n",
  "  milestone, createddate, updateddate\n",
  "intakes: intakeid, intakecode, intakestatus, progid, campus_id, intake_name,\n",
  "  intakestartdate, intakeenddate, available_spaces, funding_source, fees,\n",
  "  createddate, updateddate\n",
  "programmes: progid, progcode, progversion, progtitle, progdescription, progcrediteq,\n",
  "  progleveleq, progefts, progstatus, proglength, proglengthunits, nzqacode,\n",
  "  progress_type, createddate, updateddate\n",
  "notes: noteid, student_id, enrolmentid, notetype, notearea, confidential, createddate\n\n",
  "ENTITY FIELDS — v3 column names (snake_case throughout)\n",
  "students: id, student_status, title, gender, country_of_birth, fees_free,\n",
  "  other_id_1, other_id_2, pronoun, student_identifier, homestay,\n",
  "  primary_learning_style, secondary_learning_style, contact_id,\n",
  "  new_zealand_student_extension\n",
  "enrolments: id, student (FK char), intake (FK char), enrolment_status, start_date,\n",
  "  end_date, enrolment_status_date, return_type, attendance, completed_successfully,\n",
  "  enrolment_payer_type_id, finished_date, withdrawal_reason, withdrawal_date,\n",
  "  fees_free, other_id_1, created_at, updated_at\n",
  "components: id, component (FK char), enrolment (FK char), start_date, end_date,\n",
  "  due_date, enrolment_status, payer_type_id, funding_category, attendance, grade,\n",
  "  completion_code, completion_date, extension_date, withdrawal_date, created_at, updated_at\n",
  "intakes: id, code, intake_status, programme (FK char), campus (FK char), name,\n",
  "  start_date, end_date, created_at, updated_at\n",
  "programmes: id, code, version, title, description, efts, status, created_at, updated_at\n",
  "events (v3 only): id, student (FK), enrolment (FK), intake (FK), event_type,\n",
  "  event_subject, event_priority, event_complete, event_due_date, created_at\n",
  "component_grades (v3 only): id, enrolment_component (FK), attempt_date,\n",
  "  numerical_value, grade, created_at\n",
  "contacts: id, type_2 (v2) / contact_type (v3), gender, status, createddate/created_at\n",
  "addresses: addressid/id, addresstype/address_type, city, postcode, region, country,\n",
  "  validfrom/valid_from, validto/valid_to, studentid/student, createddate/created_at\n",
  "classes: id, class_name/name, capacity, enrolment_count, startdate/start_date,\n",
  "  enddate/end_date, campusid/campus, active, createddate/created_at\n",
  "campuses, ethnicities, countries, genders, titles: all fields (lookup tables)\n\n",
  "KEY DATE FIELDS\n",
  "v2: enrolments.enrstartdate/enrenddate, enrolments.enrwithdrawaldate,\n",
  "    enrolments.enrcompletiondate, enrolments.enrstatusdate,\n",
  "    components.compenrstartdate/compenrenddate, intakes.intakestartdate/intakeenddate\n",
  "v3: enrolments.start_date/end_date, enrolments.withdrawal_date,\n",
  "    enrolments.finished_date, enrolments.enrolment_status_date,\n",
  "    components.start_date/end_date, intakes.start_date/end_date\n",
  "Both: *.created_at, *.updated_at (v3) / *.createddate, *.updateddate (v2)\n",
  "NOTE: students entity has NO creation/update date fields from the API\n\n",
  "WORKSPACE FUNCTIONS\n",
  "- selma_get_entity(\"students\") or selma_students() — fetch + policy-filter + cache\n",
  "- selma_enrolments(), selma_intakes(), selma_components(), selma_programmes()\n",
  "- selma_events(), selma_component_grades() — v3 only\n",
  "- selma_student_pipeline(enrolments, students, intakes) — common 3-way join\n",
  "- selma_component_pipeline(components, enrolments, students, intakes) — full join\n",
  "- selma_join_students(), selma_join_intakes(), selma_join_components(),\n",
  "  selma_join_programmes(), selma_join_notes(), selma_join_attempts() — join helpers\n",
  "- Variables persist between execute_r calls\n\n",
  "ENROLMENT STATUS CODES (same in v2 and v3)\n",
  "- SELMA_STATUS_CONFIRMED   = \"C\"  — Currently enrolled, confirmed\n",
  "- SELMA_STATUS_COMPLETED   = \"FC\" — Finished, completed successfully\n",
  "- SELMA_STATUS_INCOMPLETE  = \"FI\" — Finished, did not complete\n",
  "- SELMA_STATUS_WITHDRAWN   = \"WR\" — Withdrawn (after census, still funded)\n",
  "- SELMA_STATUS_WITHDRAWN_SDR = \"WS\" — Withdrawn for SDR reporting\n",
  "- SELMA_STATUS_EARLY_WITHDRAWN = \"ER\" — Early withdrawal (before census, not funded)\n",
  "- SELMA_STATUS_DEFERRED    = \"D\"  — Deferred to a later intake\n",
  "- SELMA_STATUS_CANCELLED   = \"X\"  — Cancelled (never started)\n",
  "- SELMA_STATUS_PENDING     = \"P\"  — Pending / not yet confirmed\n\n",
  "STATUS GROUPS\n",
  "- SELMA_FUNDED_STATUSES     = c(\"C\", \"FC\", \"FI\") — revenue-generating\n",
  "- SELMA_ALL_FUNDED_STATUSES = c(\"C\", \"FC\", \"FI\", \"WR\", \"WS\") — includes withdrawn (still funded)\n",
  "- Withdrawal statuses: WR, WS, ER (use these for withdrawal queries, not pattern matching)\n\n",
  "FUNDING SOURCES\n",
  "- \"01\" = Government Funded\n",
  "- \"02\" = International Fee-Paying\n",
  "- \"29\" = MPTT Level 3-4\n",
  "- \"31\" = Youth Guarantee\n",
  "- \"37\" = Non-degree L3-7 NZQCF\n\n",
  "COMMON PATTERNS\n",
  "# Active funded enrolments — v2\n",
  "enrolments |> filter(enrstatus %in% SELMA_FUNDED_STATUSES)\n\n",
  "# Active funded enrolments — v3\n",
  "enrolments |> filter(enrolment_status %in% SELMA_FUNDED_STATUSES)\n\n",
  "# Enrolment counts by programme — v2\n",
  "pipeline <- selma_student_pipeline(selma_enrolments(), selma_students(), selma_intakes())\n",
  "pipeline |> count(progtitle, enrstatus)\n\n",
  "# Enrolment counts by programme — v3\n",
  "pipeline <- selma_student_pipeline(selma_enrolments(), selma_students(), selma_intakes())\n",
  "pipeline |> count(title, enrolment_status)\n\n",
  "# Notes with student context — v3\n",
  "notes <- selma_notes(); events <- selma_events(); students <- selma_students()\n",
  "notes_with_students <- selma_join_notes(notes, students, events = events)\n\n",
  "# EFTS by funding source (use the dedicated tool instead of code)\n",
  "get_efts_report(year = 2025)\n\n",
  "CHARTING\n",
  "- Default: generate self-contained Chart.js HTML files using save_chart().\n",
  "- Template: create an HTML string with a <canvas> element and Chart.js loaded\n",
  "  from CDN (https://cdn.jsdelivr.net/npm/chart.js), then call\n",
  "  save_chart(html, 'chart_name.html') to save it to output_dir.\n",
  "  Then browseURL() to open it.\n",
  "- IMPORTANT: writeLines() is blocked by the AST guard. Use save_chart() instead.\n",
  "- Use ggplot2 only if the user specifically requests a static PNG or the chart\n",
  "  type is not supported by Chart.js (e.g. complex faceted statistical plots).\n",
  "- For ggplot2: the server auto-detects gg objects and saves PNG + HTML wrapper.\n\n",
  "PRE-LOADED PACKAGES\n",
  "dplyr, tidyr, ggplot2, lubridate, scales"
)

# ── 18. JSON-RPC Dispatch ────────────────────────────────────────────────

send_notification <- function(method, params) {
  msg <- list(
    jsonrpc = "2.0",
    method = method,
    params = params
  )
  cat(as.character(to_json(msg)), "\n", sep = "", file = stdout())
  flush(stdout())
}

handle_request <- function(request) {
  method <- request$method
  id <- request$id
  params <- request$params

  if (method == "initialize") {
    return(list(
      jsonrpc = "2.0",
      id = id,
      result = list(
        protocolVersion = "2025-06-18",
        capabilities = list(
          tools = empty_obj()
        ),
        serverInfo = list(
          name = "selmaR",
          version = SERVER_VERSION
        ),
        instructions = SERVER_INSTRUCTIONS
      )
    ))
  }

  if (method == "notifications/initialized") {
    # Send welcome message to the end user
    has_con <- tryCatch({
      selmaR::selma_get_connection()
      TRUE
    }, error = function(e) FALSE)

    if (has_con) {
      con <- selmaR::selma_get_connection()
      domain <- gsub("https?://", "", gsub("/$", "", con$base_url))
      n_entities <- length(.mcp_policy)

      if (.mcp_config$expose_real_ids) {
        send_notification("notifications/message", list(
          level = "warning",
          data = paste0(
            "WARNING: Real student IDs and NSNs are exposed in this session. ",
            "You are responsible for the handling and protection of this PII. ",
            "This setting is logged in the audit trail."
          )
        ))
        audit_log(tool = "system", arguments = list(event = "real_ids_enabled",
                                                     config_source = "config.yml"))
      }

      send_notification("notifications/message", list(
        level = "info",
        data = paste0(
          "selmaR MCP v", SERVER_VERSION, " connected to ", domain, ".\n",
          "PII redaction active (", n_entities, " entities configured). ",
          if (.mcp_config$expose_real_ids) "IDs are REAL (not pseudonymised)." else "IDs are pseudonymised.",
          "\nTools: list_entities, describe_entity, get_entity_summary, get_efts_report, execute_r."
        )
      ))
    } else {
      send_notification("notifications/message", list(
        level = "warning",
        data = paste0(
          "selmaR MCP v", SERVER_VERSION, " started but NOT connected to SELMA.\n",
          "Configure credentials in config.yml (in cwd) or via SELMA_* environment variables.\n",
          "Tools requiring data will fail until authentication is configured."
        )
      ))
    }

    return(NULL)  # notification, no response
  }

  if (method == "tools/list") {
    return(list(
      jsonrpc = "2.0",
      id = id,
      result = list(tools = mcp_tools)
    ))
  }

  if (method == "tools/call") {
    tool_name <- params$name
    arguments <- if (!is.null(params$arguments)) params$arguments else list()

    handler <- tool_handlers[[tool_name]]
    if (is.null(handler)) {
      return(list(
        jsonrpc = "2.0",
        id = id,
        result = scan_result(
          mcp_result(list(mcp_text(paste0("Unknown tool: ", tool_name))), is_error = TRUE),
          "unknown"
        )
      ))
    }

    result <- tryCatch(
      handler(arguments),
      error = function(e) {
        mcp_log("Error in tool '", tool_name, "': ", conditionMessage(e))
        scan_result(
          mcp_result(list(mcp_text(paste0("Error: ", conditionMessage(e)))), is_error = TRUE),
          tool_name
        )
      }
    )

    return(list(
      jsonrpc = "2.0",
      id = id,
      result = result
    ))
  }

  # Unknown method
  list(
    jsonrpc = "2.0",
    id = id,
    error = list(
      code = -32601L,
      message = paste0("Method not found: ", method)
    )
  )
}

# ── 19. Auth on Startup ──────────────────────────────────────────────────

load_field_policy()

tryCatch(
  {
    # If cwd was set to a config file path instead of a directory, recover
    cwd_basename <- basename(getwd())
    if (grepl("\\.(yml|yaml)$", cwd_basename, ignore.case = TRUE)) {
      config_path <- normalizePath(getwd(), mustWork = FALSE)
      if (file.exists(config_path) && !dir.exists(config_path)) {
        mcp_log("cwd appears to be a file path, using parent directory")
        setwd(dirname(config_path))
      }
    }

    # Try cwd first, then package root for config.yml
    if (file.exists("config.yml")) {
      suppressMessages(selmaR::selma_connect(config_file = "config.yml"))
      mcp_log("Authenticated via cwd config.yml")
    } else if (nchar(pkg_root) > 0 && file.exists(file.path(pkg_root, "config.yml"))) {
      old_wd <- setwd(pkg_root)
      on.exit(setwd(old_wd), add = TRUE)
      suppressMessages(selmaR::selma_connect(config_file = "config.yml"))
      mcp_log("Authenticated via package root config.yml")
    } else {
      # Try env vars
      suppressMessages(selmaR::selma_connect())
      mcp_log("Authenticated via environment variables")
    }
  },
  error = function(e) {
    mcp_log("Warning: Authentication failed: ", conditionMessage(e))
    mcp_log("Tools requiring data access will fail. ",
            "Configure config.yml or SELMA_* env vars.")
  }
)

# ── 20. Main Loop ────────────────────────────────────────────────────────

mcp_log("Server started. Listening on stdin...")

stdin_con <- file("stdin", open = "r")

on.exit(generate_session_report(), add = TRUE)

repeat {
  line <- readLines(stdin_con, n = 1, warn = FALSE)

  if (length(line) == 0) {
    mcp_log("stdin closed, shutting down.")
    break
  }

  if (nchar(trimws(line)) == 0) next

  request <- tryCatch(
    jsonlite::fromJSON(line, simplifyVector = FALSE),
    error = function(e) {
      mcp_log("Failed to parse JSON: ", conditionMessage(e))
      NULL
    }
  )

  if (is.null(request)) {
    response <- list(
      jsonrpc = "2.0",
      id = NULL,
      error = list(code = -32700L, message = "Parse error")
    )
    cat(as.character(to_json(response)), "\n", sep = "", file = stdout())
    flush(stdout())
    next
  }

  response <- tryCatch(
    handle_request(request),
    error = function(e) {
      mcp_log("Internal error: ", conditionMessage(e))
      list(
        jsonrpc = "2.0",
        id = request$id,
        error = list(code = -32603L,
                     message = paste0("Internal error: ", conditionMessage(e)))
      )
    }
  )

  # Notifications don't get responses
  if (!is.null(response)) {
    cat(as.character(to_json(response)), "\n", sep = "", file = stdout())
    flush(stdout())
  }
}

close(stdin_con)
mcp_log("Server shut down.")
