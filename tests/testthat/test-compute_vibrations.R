test_that("standard linear vibrations work", {
	metadata = readRDS('metadata_for_test.rds')
	abundance = readRDS('abundance_data_for_test.rds') 
	bound_data = dplyr::tibble(dependent_variables=list(abundance),independent_variables=list(metadata),dsid=1)
  	expect_error(compute_vibrations(bound_data=bound_data,primary_variable='BMI',model_type='glm',features_of_interest=c("2","3","4","5"),max_vibration_num=10,proportion_cutoff=.9,cores=1,max_vars_in_model=100, nest=NULL,weights=NULL,ids=NULL,strata=NULL,family=gaussian()), regexp = NA)
})

test_that("survey-weighted vibrations work", {
	metadata = readRDS('nhanes_ind_data.rds')
	abundance = readRDS('nhanes_dep_data.rds') 
	bound_data = dplyr::tibble(dependent_variables=list(abundance),independent_variables=list(metadata),dsid=1)
  	expect_error(compute_vibrations(bound_data=bound_data,primary_variable='BMXBMI',model_type='survey',features_of_interest=c("LBDLDL","MSYS"),max_vibration_num=10,proportion_cutoff=.9,cores=1,max_vars_in_model=100, nest=TRUE,weights='WTMEC2YR',ids='SDMVPSU',strata='SDMVSTRA',family=gaussian()), regexp = NA)
})

test_that("multi-threading works", {
	metadata = readRDS('metadata_for_test.rds')
	abundance = readRDS('abundance_data_for_test.rds') 
	bound_data = dplyr::tibble(dependent_variables=list(abundance),independent_variables=list(metadata),dsid=1)
  	expect_error(compute_vibrations(bound_data=bound_data,primary_variable='BMI',model_type='glm',features_of_interest=c("2","3","4","5"),max_vibration_num=10,proportion_cutoff=.9,cores=2,max_vars_in_model=100, nest=NULL,weights=NULL,ids=NULL,strata=NULL,family=gaussian()), regexp = NA)
})
