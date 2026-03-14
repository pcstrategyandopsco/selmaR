#' MCP Server — Ask Claude About Your SELMA Data
#'
#' selmaR includes a Model Context Protocol (MCP) server that lets Claude
#' query your SELMA instance in natural language. The server runs as a local
#' JSON-RPC 2.0 stdio process and exposes 7 tools for exploring student
#' management data.
#'
#' @section Setup:
#'
#' Add the server to your Claude Code settings
#' (`~/.claude/settings.json` or project `.claude/settings.json`):
#'
#' ```json
#' {
#'   "mcpServers": {
#'     "selmaR": {
#'       "command": "Rscript",
#'       "args": ["<path-to-selmaR>/inst/mcp/server.R"],
#'       "cwd": "<path-to-project-with-config.yml>"
#'     }
#'   }
#' }
#' ```
#'
#' The server reads credentials from `config.yml` in the working directory
#' (same format as [selma_connect()]).
#'
#' @section Tools:
#'
#' The MCP server exposes the following tools to Claude:
#'
#' \describe{
#'   \item{`auth_status`}{Check connection and field policy status.}
#'   \item{`list_entities`}{List all available SELMA entity types with
#'     descriptions.}
#'   \item{`search_entities`}{Search entity types by keyword (case-insensitive,
#'     matches name and description).}
#'   \item{`describe_entity`}{Get per-column summary statistics for an entity.
#'     Returns aggregates only — never individual rows.}
#'   \item{`get_entity_summary`}{Get filtered/grouped aggregate statistics.
#'     Supports `filter_by` and `group_by` parameters.}
#'   \item{`get_efts_report`}{Generate an EFTS funding report by source and
#'     category for a given year.}
#'   \item{`execute_r`}{Execute R code in a sandboxed workspace with dplyr,
#'     tidyr, ggplot2, lubridate, and scales. Variables persist between calls.
#'     Code is inspected before execution — namespace access and I/O functions
#'     are blocked.}
#' }
#'
#' @section PII Protection (7 Defence Layers):
#'
#' Student data is sensitive. The server enforces:
#'
#' \enumerate{
#'   \item **ID pseudonymisation** — session-scoped deterministic hashing of
#'     all ID columns.
#'   \item **AST code inspection** — blocked packages and functions in
#'     `execute_r`.
#'   \item **Input allowlisting** — only the 7 tools above are exposed; no raw
#'     API access.
#'   \item **PII field policy** — configurable YAML allowlist controls which
#'     columns are visible per entity (see `inst/mcp/field_policy.yml`).
#'   \item **Hybrid data access** — structured tools return aggregates only,
#'     never individual rows.
#'   \item **Output scanning** — regex and PII dictionary checks on all
#'     responses before they leave the server.
#'   \item **Audit logging** — JSONL log of every tool call plus a session
#'     summary report.
#' }
#'
#' @section Files:
#'
#' The MCP server consists of:
#'
#' \describe{
#'   \item{`inst/mcp/server.R`}{Main MCP server (~1500 lines).}
#'   \item{`inst/mcp/field_policy.yml`}{Default PII field policy — controls
#'     which columns Claude can see for each entity.}
#'   \item{`inst/mcp/test_server.R`}{Test suite for the security layers.}
#' }
#'
#' @seealso
#' \code{vignette("mcp-examples")} for usage walkthroughs,
#' \code{vignette("mcp-server-design")} for the full security architecture.
#'
#' @name selma_mcp
#' @aliases mcp
NULL
