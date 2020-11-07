
#' Run initial association 
#'
#' Run initial association for a single feature
#' @param j feature name
#' @param independent_variables A tibble containing the independent variables you will want to vibrate over. Each column should correspond to a different variable (e.g. age), with the first column containing the sample names matching those in the column names of the dependent_variables tibble.
#' @param dependent_variables A tibble containing the information for your dependent variables (e.g. bacteria relative abundance, age). The first column should be the rownames (e.g. gene1, gene2, gene3), and the columns should correspond to different samples (e.g. individual1, individual2, etc).
#' @param primary_variable The column name from the independent_variables tibble containing the key variable you want to associate with disease in your first round of modeling (prior to vibration). For example, if you are interested fundamentally identifying how well age can predict height, you would make this value a string referring to whatever column in said dataframe refers to "age."
#' @param model_type Specifies regression type -- "glm", "survey", or "negative_binomial". Survey regression will require additional parameters (at leaset weight, nest, strata, and ids). Any model family (e.g. gaussian()), or any other parameter can be passed as an additional argument to this function.
#' @param proportion_cutoff Float between 0 and 1. Filter out dependent features that are this proportion of zeros or more (default = 1, so no filtering done.)
#' @param family GLM family (default = gaussian()). For help see help(glm) or help(family).
#' @param ids Name of column in dataframe pecifying cluster ids from largest level to smallest level. Only relevant for survey data. (Default = NULL).]
#' @param strata Name of column in dataframe with strata. Only relevant for survey data. (Default = NULL).]
#' @param weights Name of column containing sampling weights.
#' @param nest If TRUE, relabel cluster ids to enforce nesting within strata.
#' @importFrom rlang .data
#' @importFrom dplyr "%>%"
#' @keywords regression, initial assocatiation
regression <- function(j,independent_variables,dependent_variables,primary_variable,model_type,proportion_cutoff,family,ids,strata,weights,nest){
  feature_name = colnames(dependent_variables)[j+1]
  regression_df=suppressMessages(dplyr::left_join(dependent_variables %>% dplyr::select(.data$sampleID,c(feature_name)),independent_variables %>% dplyr::mutate_if(is.factor, as.character)) %>% dplyr::mutate_if(is.character, as.factor))
  regression_df = regression_df %>% dplyr::select(-.data$sampleID)
  #run regression
  if(model_type=='negative_binomial'){
    return(tryCatch(broom::tidy(MASS::glm.nb(weights=regression_df %>% dplyr::select(weights) %>% unlist %>% unname,formula=stats::as.formula(stringr::str_c("I(`", feature_name,"`) ~ ",primary_variable)),data = regression_df)) %>% dplyr::mutate(feature=feature_name),
             warning = function(w) w, 
             error = function(e) e
    ))
  }
  if(model_type=='survey'){
    options(survey.lonely.psu="adjust")
    dsn=survey::svydesign(weights=regression_df %>% dplyr::select(weights) %>% unlist %>% unname,ids=regression_df %>% dplyr::select(ids) %>% unlist %>% unname,nest=as.logical(nest),strata=regression_df %>% dplyr::select(strata)  %>% unlist %>% unname,data=regression_df)
    return(tryCatch(broom::tidy(survey::svyglm(family=family,formula=stats::as.formula(stringr::str_c("I(`", feature_name,"`) ~ ",primary_variable)),design=dsn)) %>% dplyr::mutate(feature=feature_name),
             warning = function(w) w,
             error = function(e) e
    )) 
  }
  if(model_type=='glm'){
    return(tryCatch(broom::tidy(stats::glm(weights=regression_df %>% dplyr::select(weights) %>% unlist %>% unname,family=family,formula=stats::as.formula(stringr::str_c("I(`", feature_name,"`) ~ ",primary_variable)),data = regression_df)) %>% dplyr::mutate(feature=feature_name),
             warning = function(w) w,
             error = function(e) e
    ))
  }
}

#' Run all associations for a given dataset
#'
#' Function to run all associations for dependent and indepenent features.
#' @param x merged independent an dependent data for a given dataset
#' @param primary_variable The column name from the independent_variables tibble containing the key variable you want to associate with disease in your first round of modeling (prior to vibration). For example, if you are interested fundamentally identifying how well age can predict height, you would make this value a string referring to whatever column in said dataframe refers to "age."
#' @param vibrate TRUE/FALSE -- run vibrations (default=TRUE)
#' @param model_type Specifies regression type -- "glm", "survey", or "negative_binomial". Survey regression will require additional parameters (at leaset weight, nest, strata, and ids). Any model family (e.g. gaussian()), or any other parameter can be passed as an additional argument to this function.
#' @param proportion_cutoff Float between 0 and 1. Filter out dependent features that are this proportion of zeros or more (default = 1, so no filtering done.)
#' @param family GLM family (default = gaussian()). For help see help(glm) or help(family).
#' @param ids Name of column in dataframe pecifying cluster ids from largest level to smallest level. Only relevant for survey data. (Default = NULL).]
#' @param strata Name of column in dataframe with strata. Only relevant for survey data. (Default = NULL).]
#' @param weights Name of column containing sampling weights.
#' @param nest If TRUE, relabel cluster ids to enforce nesting within strata.
#' @importFrom rlang .data
#' @importFrom dplyr "%>%"
#' @keywords regression, initial assocatiation
run_associations <- function(x,primary_variable,model_type,proportion_cutoff,vibrate,family,ids,strata,weights,nest){
  dependent_variables <- dplyr::as_tibble(x[[1]])
  colnames(dependent_variables)[[1]]='sampleID'
  toremove = which(colSums(dependent_variables %>% dplyr::select(-.data$sampleID) == 0,na.rm=TRUE)/nrow(dependent_variables)>proportion_cutoff)
  print(paste("Removing",length(toremove),"features that are at least",proportion_cutoff*100,"percent zero values."))
  dependent_variables=dependent_variables %>% dplyr::select(-(toremove+1))
  if(ncol(dependent_variables)==1){
    print('After filtering your data, you had nothing left. Try changing your filtering threshold for zero-value data and running again.')
    quit()
  }
  independent_variables <- dplyr::as_tibble(x[[2]])
  colnames(independent_variables)[[1]]='sampleID'
  print(paste('Computing',as.character(ncol(dependent_variables)-1),'associations for dataset',as.character(unname(unlist(x[[3]])))))
  colnames(dependent_variables)[1]='sampleID'
  colnames(independent_variables)[1]='sampleID'
  tokeep = independent_variables %>% dplyr::select_if(~ length(unique(.)) > 1) %>% colnames
  todrop = setdiff(colnames(independent_variables),tokeep)
  if(length(todrop)>1){
    print('Note: The following variables lack multiple levels and will be dropped should you run a vibration:')
    if(primary_variable %in% todrop){
      print('One of the variables being dropped is your variable of interethis will result in the pipeline failing. Please adjust your independent variables and try again.')
      quit()
    }
  }
  independent_variables=independent_variables %>% dplyr::select(-dplyr::all_of(todrop))
  if(ncol(independent_variables)==2){
    vibrate=FALSE
  }
  overlap = intersect(colnames(independent_variables %>% dplyr::select(-.data$sampleID)),colnames(dependent_variables %>% dplyr::select(-.data$sampleID)))
  if(length(overlap)>0){
    print('The following variables are in both the dependent and independent datasets. This may cause some some regressions to fail, though the pipeline will still run to completion.')
    print(overlap)
  }
  out = purrr::map(seq_along(dependent_variables %>% dplyr::select(-.data$sampleID)), function(j) regression(j,independent_variables,dependent_variables,primary_variable,model_type,proportion_cutoff,family,ids,strata,weights,nest))
  out_success = out[unlist(purrr::map(out,function(x) tibble::is_tibble(x)))]
  if(length(out_success)!=length(out)){
    print(paste('Dropping',length(out)-length(out_success),'features with regressions that failed to converge.'))
  }
  if(length(out_success)==0){
    print(paste("All of your regression output failed. Printing error messages to screen."))
    Sys.sleep(3)
    print(out)
    quit()
  }
  out_success = out_success %>% dplyr::bind_rows() %>% dplyr::filter(.data$term!='(Intercept)') %>% dplyr::mutate( bonferroni = stats::p.adjust(.data$p.value, method = "bonferroni"), BH = stats::p.adjust(.data$p.value, method = "BH"), BY = stats::p.adjust(.data$p.value, method = "BY"))
  out_success = out_success %>% dplyr::mutate(dataset_id=x[[3]])
  return(list('output' = out_success,'vibrate' = vibrate))
}

#' Deploy associations across datasets
#'
#' Top-level function to run all associations for all datasets.
#' @param bound_data merged independent an dependent data for all datasets
#' @param primary_variable The column name from the independent_variables tibble containing the key variable you want to associate with disease in your first round of modeling (prior to vibration). For example, if you are interested fundamentally identifying how well age can predict height, you would make this value a string referring to whatever column in said dataframe refers to "age."
#' @param vibrate TRUE/FALSE -- run vibrations (default=TRUE)
#' @param model_type Specifies regression type -- "glm", "survey", or "negative_binomial". Survey regression will require additional parameters (at leaset weight, nest, strata, and ids). Any model family (e.g. gaussian()), or any other parameter can be passed as an additional argument to this function.
#' @param proportion_cutoff Float between 0 and 1. Filter out dependent features that are this proportion of zeros or more (default = 1, so no filtering done.)
#' @param family GLM family (default = gaussian()). For help see help(glm) or help(family).
#' @param ids Name of column in dataframe pecifying cluster ids from largest level to smallest level. Only relevant for survey data. (Default = NULL).]
#' @param strata Name of column in dataframe with strata. Only relevant for survey data. (Default = NULL).
#' @param weights Name of column containing sampling weights.
#' @param nest If TRUE, relabel cluster ids to enforce nesting within strata. Only relevant for survey data. (Default = NULL).]
#' @importFrom rlang .data
#' @importFrom dplyr "%>%"
#' @keywords regression, initial assocatiation
#' @export
compute_initial_associations <- function(bound_data,primary_variable, model_type, proportion_cutoff,vibrate,family,ids,strata,weights,nest){
    output = apply(bound_data, 1, function(x) run_associations(x,primary_variable,model_type,proportion_cutoff,vibrate,family,ids,strata,weights,nest))
    output_regs = purrr::map(output, function(x) x[[1]])
    output_vib = unlist(unname(unique(purrr::map(output, function(x) x[[2]]))))
    if(FALSE %in% output_vib & vibrate!=FALSE){
      output_vib=FALSE
      print('For at least one dataset, we dropped all the variables that you could possible vibrate over due to lacking multiple levels. Vibrate parameter being set to FALSE.')
    }
    output_regs = dplyr::bind_rows(output_regs)
    saveRDS(output_regs,'foo.rds')
  return(list('output'=output_regs,'vibrate'=output_vib))
}
