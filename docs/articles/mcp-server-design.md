# MCP Server — Security Design & Implementation Plan

## Overview

This document describes the design for an MCP (Model Context Protocol)
server that exposes selmaR data to Claude.

The server is a **JSON-RPC 2.0 stdio process** — it reads JSON requests
from stdin, dispatches them to tool handlers, and writes JSON responses
to stdout. All internal diagnostics go to stderr to avoid corrupting the
protocol stream.

Six defence layers protect PII in responses: code inspection, input
allowlisting, configurable field policy, hybrid data access controls,
output scanning, and audit logging.

**Deployment model:** single user, local, same trust boundary as an R
console.

## Files to Create

| File                        | Purpose                            |
|-----------------------------|------------------------------------|
| `inst/mcp/server.R`         | Main MCP server (~1000–1200 lines) |
| `inst/mcp/field_policy.yml` | Default PII field policy           |
| `inst/mcp/test_server.R`    | Test suite for security layers     |

## Welcome Message on Initialisation

When the MCP client sends the `notifications/initialized` message, the
server sends a `notifications/message` back with `level: "info"`
containing a user-facing welcome message. This is displayed directly to
the end user in Claude Code or Claude Desktop.

The welcome message includes:

- Server name and version
- Connection status (authenticated or not)
- Field policy status (which policy file is loaded, how many entities
  are covered)
- A brief summary of what the server can do

**Default mode (IDs pseudonymised):**

    selmaR MCP v0.1.0 connected to myorg.selma.co.nz.
    PII redaction active (15 entities configured). IDs are pseudonymised.
    Tools: list_entities, describe_entity, get_entity_summary, get_efts_report, execute_r.

**When `expose_real_ids: true` is set in config.yml** (warning level):

    WARNING: Real student IDs and NSNs are exposed in this session.
    You are responsible for the handling and protection of this PII.
    This setting is logged in the audit trail.

## Security Architecture — 7 Defence Layers

### Layer 1: ID Pseudonymisation (Default On)

Student IDs and NSNs are high-value PII — they can be used to identify
individuals across systems. By default, the MCP server **pseudonymises
all ID columns** so the real values never cross the wire.

#### How it works

On server startup, a random seed is generated:

``` r

.mcp_seed <- as.character(sample.int(1e9, 1))
```

A deterministic hash function transforms IDs:

``` r

pseudonymise_id <- function(id, prefix = "S") {
  if (is.na(id) || id == "") return(id)
  hash <- substr(digest::digest(paste0(.mcp_seed, id), algo = "md5"), 1, 8)
  paste0(prefix, "-", hash)
}
```

This is applied to ID columns after the field policy filter:

| Column pattern                  | Prefix | Example      |
|---------------------------------|--------|--------------|
| `id`, `student_id`, `studentid` | `S`    | `S-a3f2c1b9` |
| `nsn`                           | `N`    | `N-7e4d2f1a` |
| `contact_id`, `contactid`       | `C`    | `C-b8e3a5d2` |
| `enrolment_id`, `enrolid`       | `E`    | `E-1c9f4b7e` |
| `intake_id`, `intakeid`         | `I`    | `I-d2a8c3f6` |

**Key property:** the hash is deterministic within a session. The same
real student ID always produces the same pseudo-ID, so joins between
entities still work correctly. The seed changes on each server restart,
so pseudo-IDs are not stable across sessions.

#### Opting in to real IDs

To expose real IDs, add an `mcp` section to `config.yml`:

``` yaml
default:
  selma:
    base_url: "https://myorg.selma.co.nz/"
    email: "api@selma.co.nz"
    password: "your_password"
  mcp:
    expose_real_ids: true
```

When `expose_real_ids: true` is set, the welcome message changes to a
**warning-level notification** requiring acknowledgement:

``` r

send_notification("notifications/message", list(
  level = "warning",
  data = paste0(
    "WARNING: Real student IDs and NSNs are exposed in this session. ",
    "You are responsible for the handling and protection of this PII. ",
    "This setting is logged in the audit trail."
  )
))
```

The opt-in is recorded in the audit log:

``` json
{
  "timestamp": "2026-03-14T10:00:01+1300",
  "event": "real_ids_enabled",
  "config_source": "config.yml"
}
```

### Layer 2: Code Inspection (`execute_r` AST Guard)

Before any R code is evaluated, the server parses it into an Abstract
Syntax Tree (AST) using [`parse()`](https://rdrr.io/r/base/parse.html)
and walks the tree to detect blocked constructs. If a match is found,
the code is **rejected without execution** and a warning is returned to
the client.

AST analysis is strictly better than string matching — it ignores
comments and string literals (no false positives on
`# don't use selmaR::`) and catches obfuscation attempts like
`get("selma_request")`.

**Blocked namespace packages** (via `::` and `:::`):

| Package    | Reason                                            |
|------------|---------------------------------------------------|
| `selmaR`   | Bypasses policy-wrapped workspace functions       |
| `httr`     | Direct HTTP access bypasses all controls          |
| `httr2`    | Direct HTTP access bypasses all controls          |
| `curl`     | Direct HTTP access bypasses all controls          |
| `jsonlite` | Could serialise/deserialise data outside controls |
| `config`   | Could read credentials from config.yml            |

**Blocked function calls:**

| Function | Reason |
|----|----|
| `eval`, `evalq` | Metaprogramming — could construct and run blocked code |
| `do.call` | Indirect function dispatch — bypass route |
| `get`, `mget`, `exists` | Object lookup by string name — bypass route |
| `getExportedValue`, `loadNamespace`, `requireNamespace` | Namespace access — bypass route |
| `Sys.getenv`, `Sys.setenv` | Could read `SELMA_PASSWORD` and other secrets |
| `system`, `system2`, `shell` | Shell execution — escape the R sandbox |
| `readLines`, `scan`, `file`, `readRDS`, [`readr::read_csv`](https://readr.tidyverse.org/reference/read_delim.html) | File I/O — could read config.yml or cached data |
| `writeLines`, `write.csv`, `saveRDS` | File I/O — could exfiltrate data to disk |
| `download.file`, `url`, `socketConnection` | Network access — could exfiltrate data |
| `match.fun` | Function lookup by string — bypass route |

**Design rationale:** none of these functions are needed for MCP
analysis sessions. The workspace provides dplyr, tidyr, ggplot2,
lubridate, scales, and the selma helper functions. All legitimate
analysis patterns (filtering, grouping, summarising, joining, charting)
are covered by tidyverse methods without needing base metaprogramming or
I/O functions.

``` r

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
      if (is.call(fn) && as.character(fn[[1]]) %in% c("::", ":::")) {
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
    list(safe = FALSE, blocked = blocked)
  } else {
    list(safe = TRUE)
  }
}
```

When code is blocked, the server returns an MCP error result:

    [BLOCKED] Your code was rejected before execution.
    Blocked constructs found: selmaR::selma_students, get
    Reason: These functions bypass PII controls or access restricted resources.
    Use the workspace functions instead (e.g. selma_students(), selma_get_entity()).

The blocked attempt is recorded in the audit log with the full list of
detected constructs.

### Layer 3: Input Allowlisting (Tool Restrictions)

Seven tools are exposed. No raw
[`selma_get()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_get.md)
or `selma_request()` access is available to Claude.

| Tool | Purpose | Returns |
|----|----|----|
| `auth_status` | Connection & policy status | No data |
| `list_entities` | Available entity types | Names + descriptions only |
| `search_entities` | Keyword search on entities | Names + descriptions only |
| `describe_entity` | Schema + column stats | Aggregates only (counts, uniques, distributions) |
| `get_entity_summary` | Filtered/grouped stats | Aggregates only (counts, means) |
| `get_efts_report` | EFTS funding breakdown | Aggregate funding totals (no PII) |
| `execute_r` | Custom R code in sandbox | Policy-filtered, code-inspected, output-scanned |

**What is NOT exposed in the workspace:**

- [`selma_connect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_connect.md)
  /
  [`selma_disconnect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_disconnect.md)
  — auth managed by server
- [`selma_get()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_get.md)
  / `selma_request()` — raw API access bypasses policy
- [`selma_get_one()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_get_one.md)
  — single-record access bypasses aggregation
- The connection object itself

### Layer 4: PII Field Allowlist (Configurable YAML)

A `field_policy.yml` defines per-entity field visibility. The file is
resolved from (first match wins):

1.  `SELMAR_FIELD_POLICY` environment variable
2.  `{cwd}/field_policy.yml` (project-specific override)
3.  `{pkg_root}/inst/mcp/field_policy.yml` (package default)

Three modes per entity:

- **`mode: allow`** — only listed fields pass through (whitelist)
- **`mode: redact`** — listed fields replaced with `[REDACTED]`
- **`mode: all`** — no restrictions (for lookup tables with no PII)

#### Default policy

``` yaml
students:
  mode: allow
  fields:
    - id
    - student_status
    - title
    - gender
    - nationality
    - ethnicity1
    - ethnicity2
    - ethnicity3
    - nz_residential_status
    - visa_type
    - third_party_id1
    - third_party_id2
    - organisation
    - created_at
    - updated_at
  # Hidden: surname, forename, preferredname, email1, email2,
  #         mobilephone, homephone, workphone, dob, nsn,
  #         passport_number, visa_number

enrolments:
  mode: allow
  fields:
    - id
    - student_id
    - intake_id
    - enrstatus
    - enrtype
    - enrolmentdate
    - withdrawaldate
    - withdrawalreason
    - completiondate
    - fundingsource
    - fundingcategory
    - created_at
    - updated_at

components:
  mode: allow
  fields:
    - compenrid
    - compid
    - enrolid
    - studentid
    - compenrstartdate
    - compenrenddate
    - compenrstatus
    - compenrefts
    - compenrsource
    - compenrfundingcategory
    - compname
    - compresult

intakes:
  mode: allow
  fields:
    - intakeid
    - progid
    - intakename
    - intakestartdate
    - intakeenddate
    - intakestatus
    - capacity
    - enrolment_count
    - campus

programmes:
  mode: allow
  fields:
    - progid
    - progname
    - progstatus
    - proglevel
    - progefts
    - progtype
    - nzqa_id
    - duration
    - delivery_mode

contacts:
  mode: allow
  fields:
    - id
    - contact_type
    - organisation
    - created_at
  # Hidden: surname, forename, email, phone, mobile

addresses:
  mode: allow
  fields:
    - addressid
    - addresstype
    - city
    - region
    - country
    - postcode
  # Hidden: street, suburb (too specific)

notes:
  mode: allow
  fields:
    - noteid
    - student_id
    - enrolmentid
    - notetype
    - notearea
    - confidential
    - created_at
  # Hidden: note1 (free text may contain PII)

organisations:
  mode: allow
  fields:
    - id
    - name
    - legalname
    - orgtype
    - country
    - registration_number

classes:
  mode: allow
  fields:
    - id
    - class_name
    - capacity
    - startdate
    - enddate
    - campusid

# Lookup entities -- no PII
campuses:
  mode: all
ethnicities:
  mode: all
countries:
  mode: all
genders:
  mode: all
titles:
  mode: all
```

#### Implementation

``` r

apply_field_policy <- function(df, entity_name) {
  policy <- .mcp_policy[[entity_name]]
  if (is.null(policy) || identical(policy$mode, "all")) return(df)

  if (identical(policy$mode, "allow")) {
    return(df[, intersect(names(df), policy$fields), drop = FALSE])
  }

  if (identical(policy$mode, "redact")) {
    for (col in intersect(names(df), policy$fields)) df[[col]] <- "[REDACTED]"
    return(df)
  }

  df
}
```

**Unknown fields are secure by default.** With `mode: allow`, any new
field returned by the API that is not in the allowlist is automatically
excluded.

### Layer 5: Hybrid Data Access

- `describe_entity` and `get_entity_summary` return **only aggregates**
  — never individual rows.
- `execute_r` provides `selma_get_entity()` which fetches, applies the
  field policy, and caches. Claude never sees raw unfiltered data.
- Entity aliases
  ([`selma_students()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_students.md)
  etc.) in the workspace shadow the real package functions, always
  applying the field policy first.
- Join helpers are exposed — they operate on already-filtered data.

### Layer 6: Output Scanning

Before any MCP response is returned, all text content is scanned for PII
using two complementary methods: regex pattern matching and a
session-specific PII dictionary. Matches are replaced with
`[REDACTED:type]`.

#### 6a. Regex Pattern Matching

Catches structurally recognisable PII regardless of source:

``` r

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
```

**Design decision:** The NSN (National Student Number) pattern — 9-digit
numbers — is excluded from the default regex set because it produces too
many false positives. NSNs are instead handled by the PII dictionary
(below).

#### 6b. PII Dictionary (Session-Specific)

The server has access to the full unfiltered data before the field
policy is applied. When an entity with PII fields is first fetched, the
server extracts the unique values from known PII columns and stores them
in an internal dictionary. This dictionary is never exposed to the
workspace.

``` r

# Columns to harvest PII values from (per entity)
PII_DICTIONARY_SOURCES <- list(
  students = c("surname", "forename", "preferredname",
               "email1", "email2", "mobilephone", "homephone",
               "workphone", "nsn"),
  contacts = c("surname", "forename", "email",
               "mobilephone", "workphone")
)

# Built during entity fetch, before field policy is applied
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
```

The dictionary scan uses **case-insensitive whole-word matching** to
minimise false positives:

``` r

scan_for_dictionary_pii <- function(text) {
  redacted <- text
  detections <- 0L

  for (val in .pii_dictionary$values) {
    pattern <- paste0("\\b", escape_regex(val), "\\b")
    if (grepl(pattern, redacted, ignore.case = TRUE)) {
      redacted <- gsub(pattern, "[REDACTED:pii]", redacted, ignore.case = TRUE)
      detections <- detections + 1L
    }
  }

  list(text = redacted, n_dictionary_hits = detections)
}
```

**How it catches what regex can’t:** if a student named “Kowalczyk”
appears in a free-text note field or a computed output string, no regex
pattern would match — but the dictionary scan catches it because
“Kowalczyk” was harvested from the `surname` column.

**False positive mitigation:**

- Minimum 3-character length threshold — filters out values like “Jo”,
  “Li”
- Whole-word boundary matching — “Lee” won’t match “employee” or “Leeds”
- Case-insensitive — catches “SMITH” even if the source was “Smith”
- Dictionary is built lazily (only when entities are fetched) so it
  doesn’t slow down startup

All redactions (both regex and dictionary) are logged to the audit
trail.

### Layer 7: Audit Log

Every tool call is logged to `{output_dir}/selma_mcp_audit.jsonl` in
JSON Lines format:

``` json
{
  "timestamp": "2026-03-14T10:15:30+1300",
  "tool": "execute_r",
  "arguments": {"code_length": 142},
  "response_bytes": 3847,
  "redactions_applied": ["email: 2 match(es)"],
  "code_blocked": false,
  "is_error": false
}
```

Blocked code attempts are also logged:

``` json
{
  "timestamp": "2026-03-14T10:16:05+1300",
  "tool": "execute_r",
  "arguments": {"code_length": 89},
  "response_bytes": 256,
  "code_blocked": true,
  "blocked_pattern": "selmaR::",
  "blocked_reason": "Direct namespace access bypasses PII policy",
  "is_error": true
}
```

The raw JSONL log can be parsed with
[`jsonlite::stream_in()`](https://jeroen.r-universe.dev/jsonlite/reference/stream_in.html)
for programmatic analysis.

#### Session Summary Report (generated on exit)

When the MCP server shuts down (stdin EOF / client disconnect), it
automatically generates a human-readable HTML summary at
`{output_dir}/selma_mcp_session_{timestamp}.html` and writes the path to
stderr. This ensures a readable audit artifact is always available, even
if the user forgets to check.

The report contains:

| Section | Content |
|----|----|
| **Session** | Start time, end time, duration, server version, SELMA domain |
| **Security** | Field policy file used, ID pseudonymisation on/off, real-ID opt-in warning if applicable |
| **Tool Calls** | Table of every call: timestamp, tool name, response size, duration |
| **Entities Accessed** | Which entities were fetched, row counts, how many times |
| **Blocked Attempts** | Any `execute_r` calls rejected by code inspection, with the blocked pattern and reason |
| **PII Redactions** | Count and type of output-scanner redactions (e.g. “3 emails, 1 NZ phone”) |
| **Warnings** | Any large-dataset warnings, timeouts, or errors |

Example shutdown log:

    [selmaR] Session summary written to: /path/to/output/selma_mcp_session_20260314_101530.html
    [selmaR] 12 tool calls | 4 entities accessed | 0 blocked | 2 redactions

Implementation:

``` r

generate_session_report <- function() {
  log_entries <- jsonlite::stream_in(file(.audit$log_path), verbose = FALSE)

  # Compute summary stats
  n_calls <- nrow(log_entries)
  n_blocked <- sum(log_entries$code_blocked %in% TRUE)
  n_errors <- sum(log_entries$is_error %in% TRUE)
  entities_accessed <- unique(log_entries$entity[!is.na(log_entries$entity)])
  all_redactions <- unlist(log_entries$redactions_applied)
  duration <- difftime(Sys.time(), .audit$session_start, units = "mins")

  # Build HTML report
  html <- build_session_html(
    session_start = .audit$session_start,
    duration = duration,
    log_entries = log_entries,
    n_calls = n_calls,
    n_blocked = n_blocked,
    n_errors = n_errors,
    entities_accessed = entities_accessed,
    redactions = all_redactions,
    real_ids_enabled = .mcp_config$expose_real_ids
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
}
```

The main loop calls this on exit:

``` r

on.exit(generate_session_report(), add = TRUE)

repeat {
  line <- readLines(stdin_con, n = 1)
  if (length(line) == 0) break
  # ... dispatch ...
}
```

## Workspace Setup

The `execute_r` tool runs code in a persistent `.mcp_workspace`
environment.

### Pre-loaded packages

dplyr, tidyr, ggplot2, lubridate, scales

### Policy-wrapped fetch functions

``` r

# Primary interface
selma_get_entity("students")   # fetch -> apply_field_policy -> cache -> return

# Convenience aliases (shadow the real package functions)
selma_students()    # => selma_get_entity("students")
selma_enrolments()  # => selma_get_entity("enrolments")
selma_intakes()     # => selma_get_entity("intakes")
selma_components()  # => selma_get_entity("components")
selma_programmes()  # => selma_get_entity("programmes")
```

### Join helpers

``` r

selma_join_students(enrolments, students)
selma_join_intakes(enrolments, intakes)
selma_student_pipeline(enrolments, students, intakes)
selma_component_pipeline(components, enrolments, students, intakes)
```

### Constants

All `SELMA_STATUS_*`, `SELMA_FUNDED_STATUSES`, and `SELMA_FUNDING_*`
constants are injected into the workspace.

### What is NOT in the workspace

- [`selma_connect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_connect.md),
  [`selma_disconnect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_disconnect.md)
  — auth managed by server
- [`selma_get()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_get.md),
  `selma_request()` — raw API access
- [`selma_get_one()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_get_one.md)
  — single-record access
- The connection object

## Runtime Guards

| Guard | Detail |
|----|----|
| **30-second timeout** | `setTimeLimit(elapsed = 30)` on every `execute_r` eval |
| **800KB response cap** | Truncate oversized responses with `[TRUNCATED]` warning |
| **Row-count reporting** | Workspace wrapper emits `[entity: N rows x M cols]` messages |
| **Large dataset warnings** | Entities \>50K rows trigger `[WARNING: filter early]` |
| **Audience annotations** | Diagnostic messages sent to `["assistant"]` only |
| **HTML escaping** | `html_esc()` on all user data in plot HTML output |
| **Filename sanitisation** | Slugified filenames for chart output (no directory traversal) |
| **stderr diagnostics** | All internal logging goes to stderr, never stdout |

## Messages

### Welcome Message (to the end user)

Sent via `notifications/message` with `level: "info"` when the client
sends `notifications/initialized`. Displayed directly to the user in
Claude Code or Claude Desktop:

    selmaR MCP v{version} connected to {domain}.
    PII redaction active ({n} entities configured).
    Tools: list_entities, describe_entity, get_entity_summary, get_efts_report, execute_r.

### Server Instructions (to Claude)

The MCP `initialize` response includes an `instructions` field. This is
sent to the assistant (Claude) context — not shown to the end user — and
front-loads domain knowledge to minimise tool call round-trips.

    selmaR MCP server — SELMA student management system data for NZ PTEs/TEOs.
    Output directory for charts: {output_dir}

    SECURITY
    - PII field filtering is active. Some fields (names, emails, phones, DOB) are
      redacted per the server's field policy. You will only see policy-allowed
      columns.
    - Do NOT use :: namespace access (e.g. selmaR::selma_students). Use the
      workspace functions provided. Blocked patterns are rejected before execution.
    - Never return raw unfiltered data. Always summarise(), count(), or head().

    WORKFLOW
    1. list_entities — see what data is available
    2. describe_entity("students") — check columns, row count, distributions
    3. get_entity_summary with filter_by/group_by — quick aggregate stats
    4. get_efts_report — EFTS funding analysis (no code needed)
    5. execute_r — custom dplyr/ggplot2 analysis (30-second timeout)

    SELMA DATA MODEL
    Students enrol into Intakes (cohorts) via Enrolments.
    Each Enrolment contains Components (individual course units with EFTS values).
    Intakes belong to Programmes (qualifications).

      students --(student_id)--> enrolments --(intake_id)--> intakes --(progid)--> programmes
                                    |
                              enrolments --(enrolid)--> components

    WORKSPACE FUNCTIONS
    - selma_get_entity("students") or selma_students() — fetch + policy-filter + cache
    - selma_enrolments(), selma_intakes(), selma_components(), selma_programmes()
    - selma_student_pipeline(enrolments, students, intakes) — common 3-way join
    - selma_component_pipeline(components, enrolments, students, intakes) — full join
    - selma_join_students(), selma_join_intakes(), selma_join_components(),
      selma_join_programmes() — individual join helpers
    - Variables persist between execute_r calls

    STATUS CODES (use these constants, do not hardcode strings)
    - SELMA_STATUS_CONFIRMED = "C"
    - SELMA_STATUS_COMPLETED = "FC"
    - SELMA_STATUS_INCOMPLETE = "FI"
    - SELMA_STATUS_WITHDRAWN = "WR"
    - SELMA_STATUS_WITHDRAWN_SDR = "WS"
    - SELMA_FUNDED_STATUSES = c("C", "FC", "FI") — revenue-generating
    - SELMA_ALL_FUNDED_STATUSES = c("C", "FC", "FI", "WR", "WS") — includes withdrawn

    FUNDING SOURCES
    - "01" = Government Funded
    - "02" = International Fee-Paying
    - "29" = MPTT Level 3-4
    - "31" = Youth Guarantee
    - "37" = Non-degree L3-7 NZQCF

    COMMON PATTERNS
    # Active funded enrolments
    enrolments |> filter(enrstatus %in% SELMA_FUNDED_STATUSES)

    # Enrolment counts by programme
    pipeline <- selma_student_pipeline(selma_enrolments(), selma_students(), selma_intakes())
    pipeline |> count(progname, enrstatus)

    # EFTS by funding source (use the dedicated tool instead of code)
    get_efts_report(year = 2025)

    CHARTING
    - Default: generate self-contained Chart.js HTML files. Write to output_dir,
      then return the file path. The file opens in the user's browser.
    - Template: create an HTML string with a <canvas> element and Chart.js loaded
      from CDN (https://cdn.jsdelivr.net/npm/chart.js), writeLines() to
      file.path(output_dir, "chart_name.html"), then browseURL() to open it.
    - Use ggplot2 only if the user specifically requests a static PNG or the chart
      type is not supported by Chart.js (e.g. complex faceted statistical plots).
    - For ggplot2: the server auto-detects gg objects and saves PNG + HTML wrapper.

    PRE-LOADED PACKAGES
    dplyr, tidyr, ggplot2, lubridate, scales

## Configuration

### Claude Desktop / Claude Code config

``` json
{
  "mcpServers": {
    "selmaR": {
      "command": "Rscript",
      "args": ["/path/to/selmaR/inst/mcp/server.R"],
      "cwd": "/path/to/project/with/config.yml"
    }
  }
}
```

### SELMA credentials (`config.yml` in `cwd`)

``` yaml
default:
  selma:
    base_url: "https://myorg.selma.co.nz/"
    email: "api@selma.co.nz"
    password: "your_password"
```

### Environment variable overrides

| Variable              | Purpose                             |
|-----------------------|-------------------------------------|
| `SELMAR_PKG_DIR`      | Path to selmaR package root         |
| `SELMAR_OUTPUT_DIR`   | Output directory for charts/reports |
| `SELMAR_FIELD_POLICY` | Path to field policy YAML           |
| `SELMA_BASE_URL`      | Credential override                 |
| `SELMA_EMAIL`         | Credential override                 |
| `SELMA_PASSWORD`      | Credential override                 |

## Prompt Injection Defence

The combination of layers provides defence-in-depth against prompt
injection attempting to exfiltrate data:

1.  **ID pseudonymisation** — Student IDs and NSNs are hashed with a
    session-scoped seed before any data reaches Claude. Even if all
    other layers fail, real IDs are never exposed unless explicitly
    opted in via config.yml.
2.  **Code inspection (AST)** — Before `execute_r` evaluates anything,
    the code is parsed into an AST and walked. Blocked namespace access
    (`selmaR::`, `httr::`, etc.), metaprogramming (`eval`, `do.call`,
    `get`), file I/O, network access, and shell commands are all
    detected and rejected. The code never runs.
3.  **Input allowlisting** — Claude cannot call arbitrary API endpoints;
    only the 7 defined tools are available.
4.  **Field policy** — Even if Claude writes
    [`selma_students()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_students.md)
    in `execute_r`, the workspace wrapper strips PII fields before the
    data reaches Claude.
5.  **Output scanning** — If PII somehow enters the response (e.g. via a
    free-text note field that wasn’t policy-filtered), two scanners
    catch it: regex patterns for emails, phones, and DOBs, plus a
    session-specific PII dictionary built from actual student names,
    NSNs, and contact details.
6.  **Audit log** — All tool calls, redactions, blocked attempts, and
    real-ID opt-ins are logged, so injection attempts are detectable in
    post-hoc review.
7.  **Server instructions** — Tell Claude never to return raw unfiltered
    data and never to use `::` namespace access, reducing the surface
    area for social engineering.

**Known limitations:**

- The AST guard blocks `eval`, `do.call`, `get`, and other
  metaprogramming functions, which closes the main bypass routes.
  However, R is a dynamic language — sufficiently creative code could
  theoretically construct function references via mechanisms not yet
  blocked (e.g. environment manipulation). The output scanner and field
  policy provide additional defence lines. For multi-user deployment,
  process-level isolation would be needed (out of scope).
- The output scanner uses regex heuristics — it will not catch all
  possible PII (e.g. free-text names that aren’t in a recognisable
  pattern). The field policy is the primary defence; the scanner is a
  safety net.

## Build Sequence

1.  Server skeleton: preamble, package loading (jsonlite, stringr, yaml,
    digest), `mcp_log()`, output directory
2.  Security engine: `pseudonymise_id()`, `check_code_safety()`,
    `load_field_policy()`, `apply_field_policy()`,
    `scan_output_for_pii()`, `audit_log()`
3.  Entity registry and cache: `ENTITY_REGISTRY`, `get_cached_entity()`
4.  Column summariser: `summarize_column()`
5.  Tool definitions: 7 tool schemas in `mcp_tools` list
6.  Tool handlers: list/describe/search/summary/efts/auth/execute_r
7.  Workspace setup: `.mcp_workspace` with policy-wrapped functions
8.  Server infrastructure: `SERVER_INSTRUCTIONS`, welcome message,
    `handle_request()`, auth-on-startup, main loop
9.  `field_policy.yml`: default policy for all entities
10. `test_server.R`: security-focused test suite
11. Documentation: this article

## Testing Strategy

| Category | What is tested |
|----|----|
| ID pseudonymisation | Same ID produces same hash within session, different seed = different hash, joins still work, opt-in disables hashing |
| AST code inspection | `::` with blocked packages, blocked function calls, `:::`, metaprogramming (`eval`/`do.call`/`get`), file I/O, network, shell — all rejected. Clean dplyr/ggplot2 code passes. Comments and strings containing blocked names do not trigger. Audit log records blocks. |
| Field policy loading | All three modes (allow/redact/all), missing policy, unknown entity |
| Output scanning (regex) | Email, NZ/AU phone, DOB patterns, clean text passthrough |
| Output scanning (dictionary) | Known surnames/names caught in free text, short values (\<3 chars) skipped, whole-word matching avoids partial hits |
| apply_field_policy | Mock tibbles with PII columns, verify filtering |
| Audit logging | Write entry, verify JSONL structure |
| Entity registry | All entries map to real selmaR functions |
| Integration (skip without creds) | End-to-end fetch + filter + scan |

## Verification

1.  `Rscript inst/mcp/test_server.R` — all security tests pass
2.  Manual test: pipe JSON-RPC requests to stdin, verify responses
3.  Configure in Claude Code, test full workflow
4.  Verify welcome message appears on connection
5.  Verify blocked code patterns are rejected with clear warnings
6.  Verify audit log is created and populated (including blocked
    attempts)
7.  Verify PII fields are absent from `describe_entity` output
8.  Verify output scanning catches emails/phones in `execute_r` results
