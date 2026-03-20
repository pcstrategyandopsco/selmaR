# Package index

## Connection & Authentication

Connect to a SELMA instance.

- [`selma_connect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_connect.md)
  : Connect to the SELMA API
- [`selma_disconnect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_disconnect.md)
  : Disconnect from the SELMA API
- [`selma_get_connection()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_get_connection.md)
  : Get the active SELMA connection

## Core Data Fetching

Fetch the main SELMA entities. Most accept optional filter parameters.

- [`selma_students()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_students.md)
  : Fetch student records from SELMA
- [`selma_enrolments()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_enrolments.md)
  : Fetch enrolment records from SELMA
- [`selma_intakes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_intakes.md)
  : Fetch intake definitions from SELMA
- [`selma_components()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_components.md)
  : Fetch enrolment components from SELMA
- [`selma_programmes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_programmes.md)
  : Fetch programme definitions from SELMA
- [`selma_intake_enrolments()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_intake_enrolments.md)
  : Fetch intake enrolments with nested components
- [`selma_get()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_get.md)
  : Fetch data from a SELMA API endpoint
- [`selma_get_one()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_get_one.md)
  : Fetch a single record from a SELMA API endpoint

## Notes, Contacts & Addresses

Student notes, external contacts, and address records.

- [`selma_notes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_notes.md)
  : Fetch notes and events from SELMA
- [`selma_contacts()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_contacts.md)
  : Fetch external contacts from SELMA
- [`selma_student_contacts()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_student_contacts.md)
  : Fetch student-contact links from SELMA
- [`selma_student_relations()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_student_relations.md)
  : Fetch student relationships from SELMA
- [`selma_student_org_contacts()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_student_org_contacts.md)
  : Fetch student-organisation-contact links from SELMA
- [`selma_addresses()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_addresses.md)
  : Fetch addresses from SELMA

## Classes & Campuses

Timetable classes, campus locations, and class assignments.

- [`selma_classes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_classes.md)
  : Fetch class definitions from SELMA
- [`selma_class_enrolments()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_class_enrolments.md)
  : Fetch class enrolment links from SELMA
- [`selma_student_classes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_student_classes.md)
  : Fetch student class assignments from SELMA
- [`selma_campuses()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_campuses.md)
  : Fetch campus locations from SELMA

## Organisations & Users

Employer/agent organisations and system users.

- [`selma_organisations()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_organisations.md)
  : Fetch organisations from SELMA
- [`selma_users()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_users.md)
  : Fetch system users from SELMA

## Awards, Grades & Fees

Qualifications, assessment attempts, grading, and fee schedules.

- [`selma_enrolment_awards()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_enrolment_awards.md)
  : Fetch enrolment awards from SELMA
- [`selma_component_attempts()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_component_attempts.md)
  : Fetch component assessment attempts from SELMA
- [`selma_component_definitions()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_component_definitions.md)
  : Fetch component definitions from SELMA
- [`selma_grading_schemes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_grading_schemes.md)
  : Fetch grading schemes from SELMA
- [`selma_intake_fees()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_intake_fees.md)
  : Fetch intake fee schedules from SELMA
- [`selma_fees_free()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_fees_free.md)
  : Fetch fees-free eligibility codes from SELMA

## Custom Fields

Custom field definitions and per-record custom field values.

- [`selma_custom_fields()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_custom_fields.md)
  : Fetch custom field definitions from SELMA
- [`selma_student_custom_fields()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_student_custom_fields.md)
  : Fetch custom field values for a student
- [`selma_enrolment_custom_fields()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_enrolment_custom_fields.md)
  : Fetch custom field values for an enrolment
- [`selma_component_custom_fields()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_component_custom_fields.md)
  : Fetch custom field values for all components in an enrolment

## Programme & Enrolment Views

Alternative views of student programmes and enrolments.

- [`selma_student_programmes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_student_programmes.md)
  : Fetch student programme records from SELMA
- [`selma_enrolments_by_campus()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_enrolments_by_campus.md)
  : Fetch enrolments by campus from SELMA
- [`selma_marketing_sources()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_marketing_sources.md)
  : Fetch marketing sources from SELMA
- [`selma_milestones()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_milestones.md)
  : Fetch a single milestone from SELMA

## Joins & Pipelines

Convenience functions for common entity joins.

- [`selma_student_pipeline()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_student_pipeline.md)
  : Build a complete student enrolment pipeline
- [`selma_component_pipeline()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_component_pipeline.md)
  : Build a full component pipeline
- [`selma_join_students()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_join_students.md)
  : Join enrolments with student details
- [`selma_join_intakes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_join_intakes.md)
  : Join enrolments with intake details
- [`selma_join_components()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_join_components.md)
  : Join components to enrolments
- [`selma_join_programmes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_join_programmes.md)
  : Join intakes to programme details
- [`selma_join_notes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_join_notes.md)
  : Join notes to students
- [`selma_join_addresses()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_join_addresses.md)
  : Join addresses to students
- [`selma_join_classes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_join_classes.md)
  : Join classes to campuses
- [`selma_join_attempts()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_join_attempts.md)
  : Join component attempts to enrolment components

## Utilities

Date parsing, phone normalisation, and URL builders.

- [`parse_selma_date()`](https://pcstrategyandopsco.github.io/selmaR/reference/parse_selma_date.md)
  : Parse SELMA date strings
- [`standardize_phone()`](https://pcstrategyandopsco.github.io/selmaR/reference/standardize_phone.md)
  : Standardise a phone number to E.164 international format
- [`standardize_phones()`](https://pcstrategyandopsco.github.io/selmaR/reference/standardize_phones.md)
  : Vectorised phone standardisation
- [`selma_student_url()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_student_url.md)
  : Build a SELMA student URL
- [`selma_enrolment_url()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_enrolment_url.md)
  : Build a SELMA enrolment URL

## EFTS Reporting

Pro-rata EFTS calculation for NZ TEOs.

- [`selma_efts_report()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_efts_report.md)
  : Generate EFTS funding report

## Reference / Lookup Tables

Fetch code tables and reference data from SELMA.

- [`selma_ethnicities()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_ethnicities.md)
  : Fetch ethnicity codes from SELMA
- [`selma_countries()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_countries.md)
  : Fetch country codes from SELMA
- [`selma_genders()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_genders.md)
  : Fetch gender codes from SELMA
- [`selma_titles()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_titles.md)
  : Fetch title codes from SELMA
- [`selma_disabilities()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_disabilities.md)
  : Fetch disability codes from SELMA
- [`selma_disability_accesses()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_disability_accesses.md)
  : Fetch disability access codes from SELMA
- [`selma_visa_types()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_visa_types.md)
  : Fetch visa type codes from SELMA
- [`selma_nz_iwis()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_nz_iwis.md)
  : Fetch NZ iwi codes from SELMA
- [`selma_nz_residential_statuses()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_nz_residential_statuses.md)
  : Fetch NZ residential status codes from SELMA
- [`selma_nz_disability_statuses()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_nz_disability_statuses.md)
  : Fetch NZ disability status codes from SELMA
- [`selma_nz_disability_support_needs()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_nz_disability_support_needs.md)
  : Fetch NZ disability support needs codes from SELMA
- [`selma_secondary_schools()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_secondary_schools.md)
  : Fetch secondary school codes from SELMA
- [`selma_secondary_quals()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_secondary_quals.md)
  : Fetch secondary qualification codes from SELMA
- [`selma_previous_activities()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_previous_activities.md)
  : Fetch previous activity codes from SELMA
- [`selma_student_statuses()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_student_statuses.md)
  : Fetch student status codes from SELMA
- [`selma_contact_types()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_contact_types.md)
  : Fetch contact types from SELMA
- [`selma_contact_statuses()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_contact_statuses.md)
  : Fetch contact statuses from SELMA
- [`selma_org_types()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_org_types.md)
  : Fetch organisation types from SELMA
- [`selma_address_types()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_address_types.md)
  : Fetch address types from SELMA
- [`selma_enr_status_codes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_enr_status_codes.md)
  : Fetch enrolment status codes from SELMA
- [`selma_withdrawal_reason_codes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_withdrawal_reason_codes.md)
  [`selma_withdrawal_codes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_withdrawal_reason_codes.md)
  : Fetch withdrawal reason codes from SELMA
- [`selma_withdrawal_status_codes()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_withdrawal_status_codes.md)
  : Fetch withdrawal status codes from SELMA
- [`selma_wish_to_studies()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_wish_to_studies.md)
  : Fetch wish-to-study codes from SELMA

## MCP Server

Ask Claude about your SELMA data via the Model Context Protocol. See
[`vignette("mcp-examples")`](https://pcstrategyandopsco.github.io/selmaR/articles/mcp-examples.md)
for usage walkthroughs.

- [`selma_mcp`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_mcp.md)
  [`mcp`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_mcp.md)
  : MCP Server — Ask Claude About Your SELMA Data

## Constants

Status codes, funded status groups, and funding source codes.

- [`SELMA_STATUS_CONFIRMED`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_status_codes.md)
  [`SELMA_STATUS_COMPLETED`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_status_codes.md)
  [`SELMA_STATUS_INCOMPLETE`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_status_codes.md)
  [`SELMA_STATUS_WITHDRAWN`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_status_codes.md)
  [`SELMA_STATUS_WITHDRAWN_SDR`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_status_codes.md)
  [`SELMA_STATUS_EARLY_WITHDRAWN`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_status_codes.md)
  [`SELMA_STATUS_DEFERRED`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_status_codes.md)
  [`SELMA_STATUS_CANCELLED`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_status_codes.md)
  [`SELMA_STATUS_PENDING`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_status_codes.md)
  : SELMA Enrolment Status Codes
- [`SELMA_FUNDED_STATUSES`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_funded_statuses.md)
  [`SELMA_ALL_FUNDED_STATUSES`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_funded_statuses.md)
  : SELMA Funded Status Groups
- [`SELMA_FUNDING_GOVT`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_funding_sources.md)
  [`SELMA_FUNDING_INTL`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_funding_sources.md)
  [`SELMA_FUNDING_MPTT`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_funding_sources.md)
  [`SELMA_FUNDING_YG`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_funding_sources.md)
  [`SELMA_FUNDING_DQ37`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_funding_sources.md)
  : SELMA Funding Source Codes
- [`SELMA_FUNDING_LABELS`](https://pcstrategyandopsco.github.io/selmaR/reference/SELMA_FUNDING_LABELS.md)
  : Funding source code to label mapping
