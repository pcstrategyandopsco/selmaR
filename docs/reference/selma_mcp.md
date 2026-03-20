# MCP Server — Ask Claude About Your SELMA Data

selmaR includes a Model Context Protocol (MCP) server that lets Claude
query your SELMA instance in natural language. The server runs as a
local JSON-RPC 2.0 stdio process and exposes 7 tools for exploring
student management data.

## Setup

Add the server to your Claude Code settings (`~/.claude/settings.json`
or project `.claude/settings.json`):

    {
      "mcpServers": {
        "selmaR": {
          "command": "Rscript",
          "args": ["<path-to-selmaR>/inst/mcp/server.R"],
          "cwd": "<directory-containing-config.yml>"
        }
      }
    }

The server reads credentials from `config.yml` in the working directory
(same format as
[`selma_connect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_connect.md)).

## Tools

The MCP server exposes the following tools to Claude:

- `auth_status`:

  Check connection and field policy status.

- `list_entities`:

  List all available SELMA entity types with descriptions.

- `search_entities`:

  Search entity types by keyword (case-insensitive, matches name and
  description).

- `describe_entity`:

  Get per-column summary statistics for an entity. Returns aggregates
  only — never individual rows.

- `get_entity_summary`:

  Get filtered/grouped aggregate statistics. Supports `filter_by` and
  `group_by` parameters.

- `get_efts_report`:

  Generate an EFTS funding report by source and category for a given
  year.

- `execute_r`:

  Execute R code in a sandboxed workspace with dplyr, tidyr, ggplot2,
  lubridate, and scales. Variables persist between calls. Code is
  inspected before execution — namespace access and I/O functions are
  blocked.

## PII Protection (7 Defence Layers)

Student data is sensitive. The server enforces:

1.  **ID pseudonymisation** — session-scoped deterministic hashing of
    all ID columns.

2.  **AST code inspection** — blocked packages and functions in
    `execute_r`.

3.  **Input allowlisting** — only the 7 tools above are exposed; no raw
    API access.

4.  **PII field policy** — configurable YAML allowlist controls which
    columns are visible per entity (see `inst/mcp/field_policy.yml`).

5.  **Hybrid data access** — structured tools return aggregates only,
    never individual rows.

6.  **Output scanning** — regex and PII dictionary checks on all
    responses before they leave the server.

7.  **Audit logging** — JSONL log of every tool call plus a session
    summary report.

## Files

The MCP server consists of:

- `inst/mcp/server.R`:

  Main MCP server (~1500 lines).

- `inst/mcp/field_policy.yml`:

  Default PII field policy — controls which columns Claude can see for
  each entity.

- `inst/mcp/test_server.R`:

  Test suite for the security layers.

## See also

[`vignette("mcp-examples")`](https://pcstrategyandopsco.github.io/selmaR/articles/mcp-examples.md)
for usage walkthroughs,
[`vignette("mcp-server-design")`](https://pcstrategyandopsco.github.io/selmaR/articles/mcp-server-design.md)
for the full security architecture.
