# Moving to SELMA API v3 — What Changes and What Gets Better

SELMA v3 is a ground-up revision of the API. If your organisation is
upgrading — or if you’re writing code that needs to work across both
versions — this article explains what is meaningfully different, what
you gain, and what (if anything) you need to update in your R code.

## The short version

selmaR handles nearly all of the v2→v3 differences automatically. In
most cases you only need to reconnect:

``` r

# Re-run selma_connect() after your SELMA instance upgrades.
# Version is auto-detected — no other changes needed for basic fetching.
con <- selma_connect()
con$api_version  # confirms "v3"
```

Where you will need to update code: **column names in your downstream
scripts**. v3 renamed most fields (e.g. `forename` → `first_name`,
`enrstatus` → `enrolment_status`). The field name change tables at the
end of this article are your reference for that.

------------------------------------------------------------------------

## What v3 does better

### 1. Server-side filtering means faster scripts

v2 had very limited server-side filtering. If you wanted enrolments for
one student, you had to fetch the whole enrolments table and filter in
R.

v3 adds proper filter parameters to the key endpoints. You can ask the
SELMA server to return only the records you need:

``` r

# Instead of fetching 50,000 enrolment records and filtering in R...
all_enrs <- selma_enrolments(con)
student_enrs <- dplyr::filter(all_enrs, student_id == 456)

# ...just fetch what you need directly:
student_enrs <- selma_enrolments(con, filter = list(student = "456"))

# Same for intakes:
upcoming <- selma_intakes(con, filter = list(`start_date[after]` = "2025-01-01"))

# And components for a specific enrolment:
comps <- selma_components(con, filter = list(enrolment = "456"))
```

Filtered calls bypass the cache automatically (the cached dataset is the
full unfiltered table), so there is no risk of a filtered call
overwriting your full cached data.

### 2. `id` is always the primary key — no surprises

v2 API responses wrapped records in Hydra JSON-LD, which included an
`@id` field containing the record’s IRI (e.g. `"/app/students/42"`).
When combined with the integer primary key also called `id`, this
created a naming collision that forced a messy workaround (`id_2`).

selmaR resolves this cleanly: `@id`, `@type`, and `@context` are
stripped from every response before any processing. The result is that
`id` in every tibble you receive is **always the integer primary key** —
clean, predictable, and joinable without casting.

``` r

students <- selma_students(con)
# id is always the integer primary key
# no id_2, no @id artifacts
head(students$id)
#> [1] 1 2 3 4 5 6
```

### 3. Foreign keys tell you exactly what they point to

In v2, foreign keys were bare integers — `student_id = 42` — with no
hint of what they referred to. In v3, foreign keys arrive as IRI
references:

    "student": "/api/students/42",
    "intake":  "/api/intakes/10"

selmaR strips these to the trailing segment (`"42"`, `"10"`) and stores
them as character columns. You get the ID value directly, and the column
name tells you the entity type. The one practical consequence is a type
cast when joining:

``` r

library(dplyr)

# id is integer; student (FK) is character after IRI stripping
enrolments |>
  mutate(student_id = as.integer(student)) |>
  left_join(students, by = c("student_id" = "id"))
```

The convenience helpers
([`selma_join_students()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_join_students.md),
[`selma_join_intakes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_join_intakes.md),
etc.) handle this cast for you.

### 4. Consistent, readable field names

v2 field names were inherited from the SELMA database and were
inconsistent — a mix of camelCase, PascalCase, and abbreviated names
(`enrstartdate`, `ThirdPartyID1`, `compenrid`).

v3 standardises to snake_case throughout. Combined with `clean_names()`
applied at read time, every tibble you receive has clean, predictable
column names:

``` r

# v2                    → v3
# enrstartdate          → start_date
# enrstatus             → enrolment_status
# compenrid             → id
# forename              → first_name
# ThirdPartyID1         → other_id_1
```

### 5. Access to more data

v3 exposes significantly more endpoints — over 200 collection endpoints
vs around 30 in v2. Many entities that were embedded as nested objects
in v2 (contacts, addresses, custom field values) now have their own
paginated endpoints and richer query support.

For endpoints that selmaR doesn’t yet have a named function for, use
[`make_entity_fetcher()`](https://pcstrategyandopsco.github.io/selmaR/reference/make_entity_fetcher.md):

``` r

# Create a reusable function for any v3 endpoint
selma_events       <- make_entity_fetcher("events")
selma_placements   <- make_entity_fetcher("placements")
selma_visas        <- make_entity_fetcher("visas")
selma_documents    <- make_entity_fetcher("documents")

events <- selma_events(con)

# Or for a one-off query:
passports <- selma_get(con, "passports")
```

The endpoint name is the v3 path segment — see the SELMA v3 OpenAPI spec
or `selma_api_docs/api_summary.md` in this repo for the full list.

------------------------------------------------------------------------

## What selmaR handles automatically

You do not need to change code for any of the following — selmaR detects
the API version and adjusts:

|  | v2 | v3 | Handled by |
|----|----|----|----|
| URL prefix | `/app/` | `/api/` | [`selma_connect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_connect.md) auto-detect |
| Auth endpoint | `api/login_check` | `api/auth` | [`selma_connect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_connect.md) auto-detect |
| Auth field names | `_username`, `_password` | `username`, `secret` | `api_version.R` registry |
| Pagination key | `hydra:member` | `member` | `extract_members()` |
| Total items key | `hydra:totalItems` | `totalItems` | `api_version.R` registry |
| Renamed endpoints | `ethnicities` | `new_zealand_ethnicities` | endpoint alias table |
| JSON-LD metadata | `@id`, `@type`, `@context` | same | dropped before processing |
| IRI foreign keys | integers | `/api/.../42` → `"42"` | `standardize_selma_data()` |

For a full list of endpoint renames that are resolved via the alias
table, see the [reference for
`selma_ethnicities()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_ethnicities.md)
and related lookup functions.

------------------------------------------------------------------------

## What you do need to update: column names

Because v3 renamed fields, any downstream code that references column
names by string will need updating when you switch instances. The tables
below are your reference.

### Students

| v2 column           | v3 column               |
|---------------------|-------------------------|
| `forename`          | `first_name`            |
| `middlename`        | `middle_name`           |
| `preferredname`     | `preferred_name`        |
| `previousname`      | `previous_name`         |
| `dob`               | `date_of_birth`         |
| `mobilephone`       | `phone_mobile`          |
| `secondaryphone`    | `phone_home`            |
| `email1`            | `email_primary`         |
| `email2`            | `email_secondary`       |
| `countryofbirth`    | `country_of_birth`      |
| `third_party_id`    | `other_id_1`            |
| `third_party_id2`   | `other_id_2`            |
| `disabilitydetails` | `disability_details`    |
| `medicalcondition`  | `medical_condition`     |
| `bank_acc`          | `bank_account`          |
| `surname`           | `surname` *(unchanged)* |

Fields **removed in v3**: `nsn`, `contacts`, `initials`,
`identitychecked`, `international`, `mainagent`, `austresidency`,
`residency`, `residentialstatus`, `passportnumber`, `passportexpiry`,
`visatype`, `visanumber`, `visaexpiry`, `ethnicity1`–`3`, `iwi1`–`3`.

Fields **new in v3**: `pronoun`, `contact_id`, `user_name`,
`email_school`, `phone_work`, `homestay`, `primary_learning_style`,
`secondary_learning_style`, `student_identifier`,
`new_zealand_student_extension`, `australia_student_extension`.

### Enrolments

| v2 column             | v3 column                                         |
|-----------------------|---------------------------------------------------|
| `student_id`          | `student` *(character, was integer)*              |
| `intake_id`           | `intake` *(character, was integer)*               |
| `enrstartdate`        | `start_date`                                      |
| `enrenddate`          | `end_date`                                        |
| `enrstatus`           | `enrolment_status` *(character code, e.g. `"C"`)* |
| `enrstatusdate`       | `enrolment_status_date`                           |
| `fundingsource`       | `enrolment_payer_type_id`                         |
| `enrwithdrawalreason` | `withdrawal_reason`                               |
| `enrwithdrawaldate`   | `withdrawal_date`                                 |
| `enrcompletiondate`   | `finished_date`                                   |

### Enrolment components

| v2 column               | v3 column                              |
|-------------------------|----------------------------------------|
| `compenrid`             | `id`                                   |
| `enrolid`               | `enrolment` *(character, was integer)* |
| `compid`                | `component` *(character, was integer)* |
| `compenrstartdate`      | `start_date`                           |
| `compenrenddate`        | `end_date`                             |
| `compenrduedate`        | `due_date`                             |
| `compenrstatus`         | `enrolment_status` *(character code)*  |
| `compenrwithdrawaldate` | `withdrawal_date`                      |
| `compenrcompletiondate` | `completion_date`                      |
| `compenrextensiondate`  | `extension_date`                       |

v2 user-defined fields (`userfieldchar1` etc.) are replaced by
`custom_field_values` in v3.

### Intakes

| v2 column         | v3 column                              |
|-------------------|----------------------------------------|
| `intakeid`        | `id`                                   |
| `intakecode`      | `code`                                 |
| `intake_name`     | `name`                                 |
| `intakestartdate` | `start_date`                           |
| `intakeenddate`   | `end_date`                             |
| `intakestatus`    | `intake_status`                        |
| `progid`          | `programme` *(character, was integer)* |

### Programmes

| v2 column         | v3 column     |
|-------------------|---------------|
| `progid`          | `id`          |
| `progcode`        | `code`        |
| `progtitle`       | `title`       |
| `progversion`     | `version`     |
| `progdescription` | `description` |

------------------------------------------------------------------------

## What v3 doesn’t have

A small number of v2 endpoints have no v3 equivalent. Functions wrapping
these endpoints detect the connection version and abort with an
informative error rather than failing silently:

``` r

# These abort on v3 connections with a clear message
selma_student_custom_fields("123", con)
#> Error: selma_student_custom_fields() uses a v2-only endpoint with no v3 equivalent.
#> ℹ Check the v3 API spec for an alternative endpoint.

selma_enrolment_custom_fields("456", con)
selma_component_custom_fields("456", con)
selma_milestones("42", con)
selma_intake_enrolments(intake_id = 123, con = con)
```

For intake enrolments specifically, the v3 approach is better — use the
`filter` argument on
[`selma_enrolments()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_enrolments.md):

``` r

# v3 equivalent — returns only enrolments for intake 123
enrolments <- selma_enrolments(con, filter = list(intake = "123"))
```

------------------------------------------------------------------------

## Supporting both versions in the same codebase

If you need scripts that run against both v2 and v3 instances, check
`con$api_version` to branch on column name differences:

``` r

name_col   <- if (con$api_version == "v3") "first_name" else "forename"
status_col <- if (con$api_version == "v3") "enrolment_status" else "enrstatus"

active <- enrolments |>
  dplyr::filter(.data[[status_col]] == SELMA_STATUS_CONFIRMED)
```

Filter parameter names also differ. Pass parameters appropriate for the
connected version:

``` r

# v2
smiths <- selma_students(con, filter = list(forename = "Alice"))

# v3
smiths <- selma_students(con, filter = list(first_name = "Alice"))
```

Unknown parameters are validated against the OpenAPI schema for the
connected version — unrecognised names emit a warning and are dropped
rather than sending a bad request to the API.

------------------------------------------------------------------------

## Checking what’s available

To inspect valid filter parameters for any entity at runtime:

``` r

# v3 filter parameters for students
selmaR:::.selma_schemas$v3$students$params

# v3 filter parameters for enrolments
selmaR:::.selma_schemas$v3$enrolments$params
```

And to confirm the detected version:

``` r

con <- selma_connect()
cat("Connected to SELMA", con$api_version, "at", con$base_url, "\n")
```
