test_that("meta-analysis works", {
	association_output = readRDS('sample_association_output.rds')
	association_output2 = association_output
	association_output2$dsid=2
	association_output_doubled = dplyr::bind_rows(association_output,association_output2)
	metaanalysis = compute_metaanalysis(association_output_doubled)
	metaanalysis_cleaned <- clean_metaanalysis(metaanalysis,dataset_num=2)
  	expect_equal(nrow(metaanalysis_cleaned),79, regexp = NA)
})
