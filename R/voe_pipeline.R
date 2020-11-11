
#' Full VoE Pipeline
#'
#' This function will run the full pipeline
#' @param dependent_variables A tibble containing the information for your dependent variables (e.g. bacteria relative abundance, age). The columns should correspond to different variables, and the rows should correspond to different units, such as individuals (e.g. individual1, individual2, etc). If passing multiple datasets, pass a named list of the same length and in the same order as the independent_variables parameter. If running from the command line, pass the path (or comma separated paths) to .rds files containing the data, one per dataset.
#' @param independent_variables A tibble containing the information for your independent variables (e.g. bacteria relative abundance, age). The columns should correspond to different variables, and the rows should correspond to different units,  (e.g. individual1, individual2, etc). If passing multiple datasets, pass a named list of the same length and in the same order as the dependent_variables parameter. If running from the command line, pass the path (or comma separated paths) to .rds files containing the data, one per dataset.
#' @param primary_variable The column name from the independent_variables tibble containing the key variable you want to associate with disease in your first round of modeling (prior to vibration). For example, if you are interested fundamentally identifying how well age can predict height, you would make this value a string referring to whatever column in said dataframe refers to "age."
#' @param constant_adjusters A character vector (or just one string) corresponding to column names in your dataset to include in every vibration. (default = NULL)
#' @param vibrate TRUE/FALSE -- run vibrations (default=TRUE)
#' @param max_vars_in_model Maximum number of variables allowed in a single fit in vibrations. In case an individual has many hundreds of metadata features, this prevents models from being fit with excessive numbers of variables. Modifying this parameter will change runtime for large datasets. For example, just computing all possible models for 100 variables is extremely slow. (default = 20)
#' @param fdr_method Your choice of method for adjusting p-values. Options are BY (default), BH, or bonferroni. Adjustment is computed for all initial, single variable, associations across all dependent features. 
#' @param fdr_cutoff Cutoff for an FDR significant association. All features with adjusted p-values initially under this value will be selected for vibrations. (default = 0.05). Setting a stringent FDR cutoff is mostly relevant when you are using a large number of dependent variables (eg >50) and want to filter those with weak initial associations.
#' @param max_vibration_num Maximum number of vibrations allowed for a single dependent variable. Setting this will also reduce runtime by reducing the number of models fit. (default = 10,000)
#' @param proportion_cutoff Float between 0 and 1. Filter out dependent features that are this proportion of zeros or more (default = 1, so no filtering will be done.)
#' @param meta_analysis TRUE/FALSE -- indicates if computing meta-analysis across multiple datasets. Set to TRUE by default if the pipeline detects multiple datasets. Setting this variable to TRUE but providing one dataset will throw an error.
#' @param model_type Specifies regression type -- "glm", "survey", or "negative_binomial". Survey regression will require additional parameters (at least weight, nest, strata, and ids). Any model family (e.g. gaussian()), or any other parameter can be passed as the family argument to this function.
#' @param family GLM family (default = gaussian()). For help see help(glm) or help(family).
#' @param ids Name of column in dataframe specifying cluster ids from largest level to smallest level. Only relevant for survey data. (Default = NULL).
#' @param strata Name of column in dataframe with strata. Relevant for survey data. (Default = NULL).
#' @param weights Name of column containing sampling weights.
#' @param nest If TRUE, relabel cluster ids to enforce nesting within strata.
#' @param confounder_analysis Run confounder analysis (default=TRUE).
#' @param cores Number of cores to be used (default = 1)
#' @importFrom dplyr "%>%"
#' @importFrom rlang .data
#' @keywords pipeline
#' @export
full_voe_pipeline <- function(dependent_variables,independent_variables,primary_variable,constant_adjusters=NULL,vibrate=TRUE,fdr_method='BY',fdr_cutoff=0.05,max_vibration_num=10000, max_vars_in_model = 20,proportion_cutoff=1,meta_analysis=FALSE, model_type='glm', cores = 1, confounder_analysis=TRUE, family = gaussian(), ids = NULL, strata = NULL, weights = NULL, nest = NULL){
  output_to_return = list()
  if(inherits(dependent_variables, "list")==TRUE){
    print('Identified multiple input datasets, preparing to run meta-analysis.')
    bound_data = dplyr::tibble(dependent_variables=dependent_variables,independent_variables=independent_variables,dsid = seq_along(independent_variables))
    dataset_num = nrow(bound_data)
    if(meta_analysis==FALSE){
      return(print('The meta_analysis variable is set to FALSE, but you appear to have passed multiple datasets. Please switch it to TRUE, and/or adjust other parameters as needed, and try again. For more information, please see the documentation.'))
    }
  }
  else{
    bound_data = dplyr::tibble(dependent_variables=list(dependent_variables),independent_variables=list(independent_variables),dsid=1)
  }
  output_to_return[['original_data']] = bound_data
  passed = pre_pipeline_data_check(dependent_variables,independent_variables,primary_variable,constant_adjusters,fdr_method,fdr_cutoff,max_vibration_num,max_vars_in_model,proportion_cutoff,meta_analysis,model_type, family, ids, strata, weights, nest)
  if(passed==TRUE){
    Sys.sleep(2)
    print('Deploying initial associations')
    association_output_full <- compute_initial_associations(bound_data, primary_variable,constant_adjusters,model_type,proportion_cutoff,vibrate, family, ids, strata, weights, nest)
    output_to_return[['initial_association_output']] = association_output_full[['output']]
    vibrate=association_output_full[['vibrate']]
    association_output=association_output_full[['output']]
    if(meta_analysis == TRUE){
      metaanalysis <- compute_metaanalysis(association_output)
      metaanalysis_cleaned <- clean_metaanalysis(metaanalysis,dataset_num)
      output_to_return[['meta_analyis_output']] = metaanalysis_cleaned
      features_of_interest = metaanalysis_cleaned %>% dplyr::filter(!!rlang::sym(fdr_method)<=as.numeric(fdr_cutoff)) %>% dplyr::select(.data$feature) %>% unique
    }
    else{
      features_of_interest = association_output %>% dplyr::filter(!!rlang::sym(fdr_method)<=as.numeric(fdr_cutoff)) %>% dplyr::select(.data$feature) %>% unique
   }
    if(length(unlist(unname(features_of_interest)))==0){
      print('No significant features found, consider adjusting parameters or data and trying again.')
      return(output_to_return)
    }
    if(vibrate==TRUE){
      output_to_return[['features_to_vibrate_over']] = features_of_interest
      vibration_output = compute_vibrations(bound_data,primary_variable,constant_adjusters,model_type,unname(unlist(features_of_interest)),max_vibration_num, proportion_cutoff,cores,max_vars_in_model,family,ids,strata, weights,nest)
      output_to_return[['vibration_variables']] = vibration_output[[2]]
      if(confounder_analysis==TRUE){
        analyzed_voe_data = analyze_voe_data(vibration_output,confounder_analysis)
        output_to_return[['vibration_output']] = analyzed_voe_data
      }
      else{
        output_to_return[['vibration_output']] = vibration_output[[1]]
      }
    }
    print('Done!')
    return(output_to_return)
  }
}
