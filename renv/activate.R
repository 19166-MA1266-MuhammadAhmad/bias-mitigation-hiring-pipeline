if (requireNamespace("renv", quietly = TRUE)) {
  renv::load(project = ".")
} else {
  message("Package 'renv' is not installed. Run install.packages('renv') and renv::restore().")
}
