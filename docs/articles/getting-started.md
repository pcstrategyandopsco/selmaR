# Getting Started with selmaR

## Overview

selmaR is an R client for the [SELMA](https://selma.co.nz/) student
management system API. SELMA is used by Private Training Establishments
(PTEs) and Tertiary Education Organisations (TEOs) across New Zealand
and Australia.

This package handles:

- **Authentication** — connect once and all functions use your session
- **Pagination** — automatic Hydra JSON-LD page traversal
- **Data cleaning** — strips JSON-LD metadata, applies `clean_names()`,
  normalises IRI references
- **API version routing** — works transparently on both SELMA v2 and v3
  instances
- **Caching** — optional RDS caching with configurable TTL

## Setup

### config.yml (Recommended)

Create a `config.yml` in your project root (**add it to `.gitignore`**):

``` yaml
default:
  selma:
    base_url: "https://myorg.selma.co.nz/"
    email: "api@selma.co.nz"
    password: "your_password"
```

Then connect:

``` r

library(selmaR)

con <- selma_connect()
```

The API version is auto-detected at connect time. Store the connection
object and pass it to fetch functions, or call
[`selma_connect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_connect.md)
without assignment to store it globally.

### Environment Variables

Alternatively, set credentials in `.Renviron`:

    SELMA_BASE_URL=https://myorg.selma.co.nz/
    SELMA_EMAIL=api@selma.co.nz
    SELMA_PASSWORD=your_password

### Direct Credentials

``` r

con <- selma_connect(
  base_url = "https://myorg.selma.co.nz/",
  email    = "api@selma.co.nz",
  password = "your_password"
)
```

Credentials are resolved in priority order: direct arguments \>
config.yml \> environment variables.

------------------------------------------------------------------------

## Fetching Data

All fetch functions return tibbles with `clean_names()` applied. The
integer primary key is always in `id`. In SELMA v3, foreign key columns
(e.g. `student`, `intake`, `enrolment`) contain the trailing ID segment
extracted from their IRI reference (e.g. `"/api/students/42"` → `"42"`
as a character string).

### Core Entities

``` r

students   <- selma_students(con)
enrolments <- selma_enrolments(con)
intakes    <- selma_intakes(con)
components <- selma_components(con)
programmes <- selma_programmes(con)
```

### Filtering at the API Level

The core entity functions (`selma_students`, `selma_enrolments`,
`selma_intakes`, `selma_components`, `selma_programmes`) use a `filter`
list for server-side filtering. Valid parameter names are validated
against the OpenAPI spec for your API version — unknown params warn and
are dropped.

``` r

# Students by surname (v2) or first name (v3)
smiths <- selma_students(con, filter = list(surname = "Smith"))

# v3: filter by first_name
smiths <- selma_students(con, filter = list(first_name = "Alice"))

# Enrolments for a specific intake or student (v3 only)
enrs <- selma_enrolments(con, filter = list(intake = "123"))
enrs <- selma_enrolments(con, filter = list(student = "456"))

# Components for a specific enrolment
comps <- selma_components(con, filter = list(enrolment = "456"))

# Intakes by date range
upcoming <- selma_intakes(con, filter = list(`start_date[after]` = "2025-01-01"))
```

To see valid filter parameters for a given function and API version:

``` r

# Valid params are in the schema registry
selmaR:::.selma_schemas$v3$students$params
selmaR:::.selma_schemas$v3$enrolments$params
```

**Note:** Caching is automatically bypassed when a filter is applied —
filtered results represent a subset and must not overwrite the full
cached dataset.

### Fetching a Single Record

``` r

student  <- selma_get_one("students",   "123", con)
enrolment <- selma_get_one("enrolments", "456", con)
```

### Beyond the Core Entities

selmaR wraps a broad set of SELMA endpoints — notes, contacts,
addresses, classes, organisations, campuses, awards, and all
reference/lookup tables:

``` r

notes      <- selma_notes(con)
addresses  <- selma_addresses(con)
classes    <- selma_classes(con)
campuses   <- selma_campuses(con)
orgs       <- selma_organisations(con)
contacts   <- selma_contacts(con)
attempts   <- selma_component_attempts(con)
```

### Custom Fields (v2 only)

The custom field value endpoints (`app/student/custom/`,
`app/enrolment/custom/`) are v2-only. Calling them on a v3 connection
raises an informative error.

``` r

# v2 only — aborts with a clear message on v3
student_cf <- selma_student_custom_fields("123", con)
enrol_cf   <- selma_enrolment_custom_fields("456", con)
comp_cf    <- selma_component_custom_fields("456", con)
```

### Intake Enrolments (v2 only)

``` r

# v2 only
ie <- selma_intake_enrolments(intake_id = 123, con = con)

# v3 equivalent — use selma_enrolments() with a filter
enrs <- selma_enrolments(con, filter = list(intake = "123"))
```

### Lookup / Reference Tables

SELMA exposes many reference code tables. selmaR wraps them all:

``` r

ethnicities <- selma_ethnicities(con)
countries   <- selma_countries(con)
genders     <- selma_genders(con)
visa_types  <- selma_visa_types(con)
iwis        <- selma_nz_iwis(con)
# ... and many more — see the package reference index
```

------------------------------------------------------------------------

## Querying Endpoints Without a Named Function

SELMA v3 has over 200 collection endpoints. selmaR does not wrap all of
them. Use
[`make_entity_fetcher()`](https://pcstrategyandopsco.github.io/selmaR/reference/make_entity_fetcher.md)
to create a function for any endpoint, or
[`selma_get()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_get.md)
for a one-off query.

``` r

# Create a reusable function for an endpoint not yet in the package:
selma_events     <- make_entity_fetcher("events")
selma_placements <- make_entity_fetcher("placements")
selma_visas      <- make_entity_fetcher("visas")
selma_documents  <- make_entity_fetcher("documents")

events <- selma_events(con)

# For a one-off query:
passports <- selma_get(con, "passports")
```

The endpoint name should be the v3 path segment (e.g. `"events"` for
`/api/events`). See the SELMA v3 OpenAPI spec for the full list.

------------------------------------------------------------------------

## Joining Entities

Use the convenience join functions — no need to remember join keys:

``` r

library(dplyr)

# Build a full student pipeline in one line
pipeline <- selma_student_pipeline(enrolments, students, intakes)

# Or use individual join helpers
selma_join_students(enrolments, students)     # enrolments + student details
selma_join_intakes(enrolments, intakes)       # enrolments + intake dates
selma_join_components(components, enrolments) # components + enrolment info
selma_join_programmes(intakes, programmes)    # intakes + programme names
selma_join_notes(notes, students)             # notes + student details
selma_join_addresses(addresses, students)     # addresses + student details
selma_join_classes(classes, campuses)         # classes + campus locations
selma_join_attempts(attempts, components)     # attempts + component details

# Full component pipeline: components + enrolments + students + intakes
full <- selma_component_pipeline(components, enrolments, students, intakes)
```

**Note on joining v3 data:** In v3, foreign key columns like `student`
and `intake` contain character IDs (e.g. `"42"`), while primary key `id`
columns are integers. Use
[`as.integer()`](https://rdrr.io/r/base/integer.html) or
[`as.character()`](https://rdrr.io/r/base/character.html) to align types
before joining:

``` r

enrolments |>
  dplyr::mutate(student_id = as.integer(student)) |>
  dplyr::left_join(students, by = c("student_id" = "id"))
```

------------------------------------------------------------------------

## Using the Cache

Enable caching to avoid slow API calls on repeated runs. The cache
stores the full unfiltered dataset and is bypassed automatically when
filters are applied.

``` r

students   <- selma_students(con, cache = TRUE, cache_dir = "data", cache_hours = 24)
enrolments <- selma_enrolments(con, cache = TRUE)
```

------------------------------------------------------------------------

## Status Code Constants

Use the exported constants rather than raw strings:

``` r

# Active funded enrolments (v3 uses enrolment_status; v2 uses enrstatus)
enrolments |>
  dplyr::filter(enrolment_status %in% c(SELMA_STATUS_CONFIRMED, SELMA_STATUS_COMPLETED))

# All funded statuses (including withdrawn)
SELMA_ALL_FUNDED_STATUSES
#> [1] "C"  "FC" "FI" "WR" "WS"
```

------------------------------------------------------------------------

## URL Builders

Generate deep links to SELMA records:

``` r

selma_student_url(123, "https://myorg.selma.co.nz/")
#> "https://myorg.selma.co.nz/en/admin/student/123/1"

selma_enrolment_url(456, "https://myorg.selma.co.nz/")
#> "https://myorg.selma.co.nz/en/admin/enrolment/456/1"
```
