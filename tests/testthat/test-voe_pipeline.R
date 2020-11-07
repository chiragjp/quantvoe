test_that("non-meta-analytic pipeline works", {
	metadata = readRDS('metadata_for_test.rds')
	abundance = readRDS('abundance_data_for_test.rds')
  	expect_error(full_voe_pipeline(abundance,metadata,primary_variable='BMI',fdr_method='BY',model_type='glm',family=gaussian(),fdr_cutoff=0.99,max_vibration_num=10,proportion_cutoff = 0.9,max_vars_in_model=20,meta_analysis=FALSE, cores =1,vibrate=TRUE, nest=NULL,weights=NULL,ids=NULL,strata=NULL), regexp = NA)
})

test_that("meta-analytic pipeline works", {
	metadata = readRDS('metadata_for_test.rds')
	abundance = readRDS('abundance_data_for_test.rds')
  	expect_error(full_voe_pipeline(list('dataset1'=abundance,'dataset2'=abundance),list('dataset1'=metadata,'dataset2'=metadata),model_type='glm',family=gaussian(),primary_variable='BMI',max_vars_in_model=20,fdr_method='BY',fdr_cutoff=0.99,max_vibration_num=10,proportion_cutoff = 0.9, meta_analysis=TRUE, cores =1,vibrate=TRUE, nest=NULL,weights=NULL,ids=NULL,strata=NULL), regexp = NA)
})
