#' Build a cache file path
#' @noRd
cache_path <- function(cache_dir, entity) {
  file.path(cache_dir, paste0("selma_", entity, ".rds"))
}

#' Check if a cache file is fresh
#' @noRd
cache_is_fresh <- function(path, cache_hours) {
  if (!file.exists(path)) return(FALSE)
  mtime <- file.info(path)$mtime
  hours_since <- as.numeric(difftime(Sys.time(), mtime, units = "hours"))
  hours_since < cache_hours
}

#' Load cached data
#' @noRd
cache_load <- function(path, entity) {
  if (!file.exists(path)) return(NULL)
  data <- readRDS(path)
  cli_alert_info("Loaded {nrow(data)} {entity} from cache")
  data
}

#' Save data to cache
#' @noRd
cache_save <- function(data, path, entity) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(data, path)
  cli_alert_success("Cached {nrow(data)} {entity} to {.file {path}}")
  invisible(data)
}
