# Run this script once to initialize renv and snapshot all tutorial dependencies.
# Execute from the ars_learnr_tutorial/ directory.

# Step 1: Install renv if not already installed
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}

# Step 2: Initialize renv in this project folder
renv::init()

# Step 3: Install remotes first (needed for GitHub packages)
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

# Step 4: Install all tutorial dependencies from CRAN
install.packages(c(
  "learnr",
  "dplyr",
  "jsonlite",
  "glue",
  "haven",
  "knitr",
  "rmarkdown",
  "pharmaverseadam",
  "pharmaversesdtm",
  "cards",
  "cardx",
  "gtsummary",
  "admiral"
))

# gradethis is GitHub-only — must be installed via remotes
remotes::install_github("rstudio/gradethis")

# Step 5: Snapshot the environment — creates renv.lock
renv::snapshot()

message("renv snapshot complete. Commit renv.lock to version control.")
