test_that("metadata analysis works", {
  metadata <- readRDS('metadata_for_test.rds')
  metadata <- metadata[2:length(metadata)]
  testthat::expect_error(ind_var_analysis(metadata), regexp = NA)
  system('rm -rf Metadata_Files')
  ind_var_analysis(metadata)
  system('rm -rf Metadata_Files')
})
