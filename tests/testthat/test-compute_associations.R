test_that("linear regression works", {
	metadata = readRDS('metadata_for_test.rds')
	abundance = readRDS('abundance_data_for_test.rds') 
	bound_data = dplyr::tibble(dependent_variables=list(abundance),independent_variables=list(metadata),dsid=1)
  	expect_error(compute_initial_associations(bound_data,primary_variable='BMI',model_type = 'glm',family=gaussian(),proportion_cutoff = 0.9,vibrate=TRUE, nest=NULL,weights=NULL,ids=NULL,strata=NULL), regexp = NA)
})

test_that("negative binomial regression works", {
	metadata = readRDS('metadata_ag_fecal_for_test.rds')
	abundance = readRDS('ag_data_for_nb_test.rds') 
	bound_data = dplyr::tibble(dependent_variables=list(abundance),independent_variables=list(metadata),dsid=1)
  	expect_error(compute_initial_associations(bound_data,vibrate=TRUE,primary_variable='BMI_CORRECTED',model_type = 'negative_binomial',proportion_cutoff = 0.9,nest=NULL,weights=NULL,ids=NULL,strata=NULL,family=gaussian()), regexp = NA)
})

test_that("survey weighted regression works", {
	metadata = readRDS('nhanes_ind_data.rds')
	abundance = readRDS('nhanes_dep_data.rds') 
	bound_data = dplyr::tibble(dependent_variables=list(abundance),independent_variables=list(metadata),dsid=1)
  	expect_error(compute_initial_associations(bound_data,primary_variable='RIDAGEYR',model_type = 'survey',proportion_cutoff = 0.9,vibrate=TRUE, nest=TRUE,weights='WTMEC2YR',ids='SDMVPSU',strata='SDMVSTRA',family=gaussian()), regexp = NA)
})