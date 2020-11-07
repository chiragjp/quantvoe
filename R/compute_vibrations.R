#' Vibration for feature
#'
#' Run vibrations for a single feature
#' @param merged_data Merged independent and dependent data.
#' @param variables_to_vibrate Variables over which you're going to vibrate.
#' @param max_vars_in_model Maximum number of variables allowed in in a model.
#' @param feature Feature over which to vibrate.
#' @param primary_variable The column name from the independent_variables tibble containing the key variable you want to associate with disease in your first round of modeling (prior to vibration). For example, if you are interested fundamentally identifying how well age can predict height, you would make this value a string referring to whatever column in said dataframe refers to "age."
#' @param dataset_id Identifier for dataset.
#' @param model_type Specifies regression type -- "glm", "survey", or "negative_binomial". Survey regression will require additional parameters (at leaset weight, nest, strata, and ids). Any model family (e.g. gaussian()), or any other parameter can be passed as an additional argument to this function.
#' @param proportion_cutoff Float between 0 and 1. Filter out dependent features that are this proportion of zeros or more (default = 1, so no filtering done.)
#' @param max_vibration_num Maximum number of vibrations (default=10000).
#' @param family GLM family (default = gaussian()). For help see help(glm) or help(family).
#' @param ids Name of column in dataframe pecifying cluster ids from largest level to smallest level. Only relevant for survey data. (Default = NULL).]
#' @param strata Name of column in dataframe with strata. Only relevant for survey data. (Default = NULL).]
#' @param weights Name of column containing sampling weights.
#' @param nest If TRUE, relabel cluster ids to enforce nesting within strata.#' @keywords regression, initial assocatiation
#' @importFrom rlang .data
#' @importFrom dplyr %>%
vibrate <- function(merged_data,variables_to_vibrate,max_vars_in_model,feature,primary_variable,model_type,max_vibration_num,dataset_id,proportion_cutoff,family,ids,strata,weights,nest){
    if(is.null(max_vars_in_model)==FALSE){
      if(max_vars_in_model < length(variables_to_vibrate)){
        random_list = sample.int(max_vars_in_model,max_vibration_num,replace=TRUE)
        varset = purrr::map(random_list, function(x) sample(variables_to_vibrate,x))
      }
      else{
        varset=rje::powerSet(variables_to_vibrate)        
      }
    }
    else{
      varset=rje::powerSet(variables_to_vibrate)
    }
    if(length(varset)>as.numeric(max_vibration_num)){
      varset=sample(varset,as.numeric(max_vibration_num))
    }
    regression_df = merged_data %>% dplyr::select(c(dplyr::all_of(feature),dplyr::all_of(primary_variable),dplyr::all_of(weights),dplyr::all_of(strata),dplyr::all_of(ids),dplyr::all_of(variables_to_vibrate)))
    if(model_type=='negative_binomial'){
        return(tibble::tibble(
        dependent_feature = feature,
        independent_feature = primary_variable,
        dataset_id = dataset_id,
        vars = varset,
        full_fits = purrr::map(.data$vars, function(y) tryCatch(broom::tidy(MASS::glm.nb(formula=stats::as.formula(paste("I(`",feature,"`) ~ ",primary_variable,'+',paste(y,collapse='+',sep='+'),sep='',collapse='')),weights=regression_df %>% dplyr::select(dplyr::all_of(weights)) %>% unlist %>% unname,data = regression_df)),warning = function(w) w, error = function(e) e)),
        feature_fit = purrr::map(.data$full_fits, function(x) tryCatch(dplyr::filter(x, grepl(primary_variable,.data$term)),warning = function(w) w,error = function(e) e)
        )
      ))
     }
    if(model_type=='survey'){
      dsn=survey::svydesign(weights=regression_df %>% dplyr::select(dplyr::all_of(weights)) %>% unlist %>% unname,ids=regression_df %>% dplyr::select(dplyr::all_of(ids)) %>% unlist %>% unname,nest=as.logical(nest),strata=regression_df %>% dplyr::select(dplyr::all_of(strata))  %>% unlist %>% unname,data=regression_df)
        return(tibble::tibble(
        dependent_feature = feature,
        independent_feature = primary_variable,
        dataset_id = dataset_id,
        vars = varset,
        full_fits = purrr::map(.data$vars, function(y) tryCatch(broom::tidy(survey::svyglm(family=family,formula=stats::as.formula(paste("I(`",feature,"`) ~ ",primary_variable,'+',paste(y,collapse='+',sep='+'),sep='',collapse='')),design=dsn)),warning = function(w) w, error = function(e) e)),
        feature_fit = purrr::map(.data$full_fits, function(x) tryCatch(dplyr::filter(x, grepl(primary_variable,.data$term)),warning = function(w) w,error = function(e) e)
        )
      ))
     }
    if(model_type=='glm'){
        return(tibble::tibble(
        dependent_feature = feature,
        independent_feature = primary_variable,
        dataset_id = dataset_id,
        vars = varset,
        full_fits = purrr::map(.data$vars, function(y) tryCatch(broom::tidy(stats::glm(formula=stats::as.formula(paste("I(`",feature,"`) ~ ",primary_variable,'+',paste(y,collapse='+',sep='+'),sep='',collapse='')),weights=regression_df %>% dplyr::select(dplyr::all_of(weights)) %>% unlist %>% unname,family=family,data = regression_df)),warning = function(w) w, error = function(e) e)),
        feature_fit = purrr::map(.data$full_fits, function(x) tryCatch(dplyr::filter(x, grepl(primary_variable,.data$term)),warning = function(w) w,error = function(e) e)
        )
      ))
    }
}

#' Vibration for dataset
#'
#' Run vibrations for all features in a dataset
#' @param subframe List of length 2. Dataframes containing a single datasets independent and dependent data.
#' @param max_vars_in_model Maximum number of variables allowed in in a model.
#' @param max_vibration_num Maximum number of vibrations (default=50000).
#' @param primary_variable The column name from the independent_variables tibble containing the key variable you want to associate with disease in your first round of modeling (prior to vibration). For example, if you are interested fundamentally identifying how well age can predict height, you would make this value a string referring to whatever column in said dataframe refers to "age."
#' @param model_type Specifies regression type -- "glm", "survey", or "negative_binomial". Survey regression will require additional parameters (at leaset weight, nest, strata, and ids). Any model family (e.g. gaussian()), or any other parameter can be passed as an additional argument to this function.
#' @param proportion_cutoff Float between 0 and 1. Filter out dependent features that are this proportion of zeros or more (default = 1, so no filtering done).
#' @param features_of_interest Feature to vibrate over.
#' @param cores Number of threads.
#' @param family GLM family (default = gaussian()). For help see help(glm) or help(family).
#' @param ids Name of column in dataframe pecifying cluster ids from largest level to smallest level. Only relevant for survey data. (Default = NULL).]
#' @param strata Name of column in dataframe with strata. Only relevant for survey data. (Default = NULL).]
#' @param weights Name of column containing sampling weights.
#' @param nest If TRUE, relabel cluster ids to enforce nesting within strata.
#' @importFrom rlang .data
#' @importFrom dplyr %>%
#' @keywords regression, initial assocatiation
dataset_vibration <-function(subframe,primary_variable,model_type,features_of_interest,max_vibration_num, proportion_cutoff,cores,max_vars_in_model,family,ids,strata,weights,nest){
  print(paste('Computing vibrations for',length(features_of_interest),'features in dataset number',subframe[[3]]))
  dep_sub = subframe[[1]]
  in_sub = subframe[[2]]
  colnames(dep_sub)[[1]]='sampleID'
  colnames(in_sub)[[1]]='sampleID'
  tokeep = in_sub %>% dplyr::select_if(~ length(unique(.)) > 1) %>% colnames
  todrop = setdiff(colnames(in_sub),tokeep)
  if(length(todrop)>1){
    in_sub=in_sub %>% dplyr::select(-dplyr::all_of(todrop))
  }
  features_of_interest = intersect(features_of_interest,colnames(dep_sub))
  dep_sub = dep_sub %>% dplyr::select(.data$sampleID,c(features_of_interest))
  variables_to_vibrate=colnames(in_sub %>% dplyr::select(-c(.data$sampleID,dplyr::all_of(strata),dplyr::all_of(weights),dplyr::all_of(ids),dplyr::all_of(primary_variable))))
  merged_data=suppressMessages(dplyr::left_join(in_sub %>% dplyr::mutate_if(is.factor, as.character), dep_sub %>% dplyr::mutate_if(is.factor, as.character)) %>% dplyr::mutate_if(is.character, as.factor))
  if(as.integer(cores)>1){
    options(future.globals.maxSize = +Inf)
    future::plan(future::multisession, workers = as.integer(cores))
    output = furrr::future_map(features_of_interest, function(x) vibrate(merged_data, variables_to_vibrate, max_vars_in_model, x, primary_variable,model_type,max_vibration_num, subframe[[3]],proportion_cutoff,family,ids,strata,weights,nest))
  }
  else{
    output = purrr::map(features_of_interest, function(x) vibrate(merged_data, variables_to_vibrate, max_vars_in_model, x, primary_variable,model_type,max_vibration_num, subframe[[3]],proportion_cutoff,family,ids,strata,weights,nest))
  }
    dplyr::bind_rows(output)
}

#' Vibrations
#'
#' Run vibrations for all features for all datasets
#' @param bound_data Dataframe of tibbles. All independent and depenendent dataframes for all datasets.
#' @param max_vars_in_model Maximum number of variables allowed in in a model.
#' @param max_vibration_num Maximum number of vibrations (default=10000).
#' @param primary_variable The column name from the independent_variables tibble containing the key variable you want to associate with disease in your first round of modeling (prior to vibration). For example, if you are interested fundamentally identifying how well age can predict height, you would make this value a string referring to whatever column in said dataframe refers to "age."
#' @param model_type Specifies regression type -- "glm", "survey", or "negative_binomial". Survey regression will require additional parameters (at leaset weight, nest, strata, and ids). Any model family (e.g. gaussian()), or any other parameter can be passed as an additional argument to this function.
#' @param proportion_cutoff Float between 0 and 1. Filter out dependent features that are this proportion of zeros or more (default = 1, so no filtering done).
#' @param features_of_interest Feature to vibrate over.
#' @param cores Number of threads.
#' @param family GLM family (default = gaussian()). For help see help(glm) or help(family).
#' @param ids Name of column in dataframe specifying cluster ids from largest level to smallest level. Only relevant for survey data. (Default = NULL).]
#' @param strata Name of column in dataframe with strata. Only relevant for survey data. (Default = NULL).
#' @param weights Name of column containing sampling weights.
#' @param nest If TRUE, relabel cluster ids to enforce nesting within strata
#' @keywords regression, initial assocatiation
#' @importFrom rlang .data
#' @importFrom dplyr %>%
#' @export
compute_vibrations <- function(bound_data,primary_variable,model_type,features_of_interest,max_vibration_num,proportion_cutoff,cores,max_vars_in_model,family,ids,strata,weights,nest){
  output = dplyr::bind_rows(apply(bound_data, 1, function(subframe) dataset_vibration(subframe, primary_variable,model_type ,features_of_interest,max_vibration_num, proportion_cutoff,cores,max_vars_in_model,family,ids,strata,weights,nest)))
  output = output %>% dplyr::filter(!is.na(.data$dependent_feature))
  vibration_variables = unique(unlist(unname(apply(bound_data, 1, function(subframe) subframe[[2]] %>% dplyr::select(-.data$sampleID,-primary_variable) %>% colnames))))
  return(list('vibration_output'=output,'vibration_variables'=vibration_variables))
}

