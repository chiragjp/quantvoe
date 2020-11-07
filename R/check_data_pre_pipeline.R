
#' Pre-flight checks
#'
#' Check datasets and print pre-run statistics prior to deployment.
#' @param dependent_variables A tibble containing the information for your dependent variables (e.g. bacteria relative abundance, age). The first column should be the rownames (e.g. gene1, gene2, gene3), and the columns should correspond to different samples (e.g. individual1, individual2, etc).
#' @param independent_variables A tibble containing the independent variables you will want to vibrate over. Each column should correspond to a different variable (e.g. age), with the first column containing the sample names matching those in the column names of the dependent_variables tibble.
#' @param primary_variable The column name from the independent_variables tibble containing the key variable you want to associate with disease in your first round of modeling (prior to vibration). For example, if you are interested fundamentally identifying how well age can predict height, you would make this value a string referring to whatever column in said dataframe refers to "age."
#' @param max_vars_in_model Maximum number of variables allowed in a single fit (for vibrations). (default=NULL)
#' @param fdr_method Your choice of method for adjusting p-values. Options are BY (default), BH, or bonferroni.
#' @param fdr_cutoff Cutoff for an FDR significant association (default = 0.05).
#' @param max_vibration_num Maximum number of vibrations (default=50000).
#' @param proportion_cutoff Float between 0 and 1. Filter out dependent features that are this proportion of zeros or more (default = 1, so no filtering done.)
#' @param meta_analysis TRUE/FALSE -- indicates if computing meta-analysis across multiple datasets.
#' @param model_type Specifies regression type -- "glm", "survey", or "negative_binomial". Survey regression will require additional parameters (at leaset weight, nest, strata, and ids). Any model family (e.g. gaussian()), or any other parameter can be passed as an additional argument to this function.
#' @param family GLM family (default = gaussian()). For help see help(glm) or help(family).
#' @param ids Name of column in dataframe pecifying cluster ids from largest level to smallest level. Only relevant for survey data. (Default = NULL).
#' @param strata Name of column in dataframe with strata. Only relevant for survey data. (Default = NULL).]
#' @param weights Name of column containing sampling weights.
#' @param nest If TRUE, relabel cluster ids to enforce nesting within strata.
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#' @keywords pipeline
pre_pipeline_data_check <- function(dependent_variables,independent_variables,primary_variable,fdr_method,fdr_cutoff,max_vibration_num,max_vars_in_model,proportion_cutoff,meta_analysis,model_type,family,ids,strata,weights,nest){
  print('Checking input data...')
  if(model_type=='survey'){
    print('Running a survey weighted regression, using the following passed parameters for the design:')
    print(paste('weight = ',weights))
    print(paste('ids = ',ids))
    print(paste('strata = ',strata))
    print(paste('nest =',nest))
  }
  if(meta_analysis==TRUE){
    print(paste('Primary variable of interest: ',primary_variable,sep=''))
    print(paste('FDR method: ',fdr_method,sep=''))
    print(paste('FDR cutoff: ',as.character(fdr_cutoff),sep=''))
    print(paste('Max number of vibrations (if vibrate=TRUE): ',as.character(max_vibration_num),sep=''))
    print(paste('Model type: ',model_type,sep=''))
    print(paste('Family: ',family[[1]],sep=''))
    print(paste('Max number of independent features per vibration (if vibrate=TRUE): ',as.character(max_vars_in_model),sep=''))
    print(paste('Only keeping features that are at least',proportion_cutoff*100,'percent nonzero.'))
    num_features = purrr::map(dependent_variables, function(x) ncol(x)-1)
    num_samples = purrr::map(dependent_variables, function(x) nrow(x)-1)
    num_ind = purrr::map(independent_variables, function(x) ncol(x)-1)
    data_summary = dplyr::bind_cols(list('Number of features' = unlist(unname(num_features)),'Number of samples' = unlist(unname(num_samples)),'Number of adjusters' = unlist(unname(num_ind)))) %>% dplyr::mutate(dataset_number=seq_along(num_features)) %>% dplyr::mutate(max_models_per_feature = .data$`Number of adjusters`*max_vibration_num)
    message('Preparing to run pipeline with the following parameters:')
    print((data_summary))
    Sys.sleep(2)
    max_models = sum(data_summary$max_models_per_feature*data_summary$`Number of features`)
    print(paste('This works out to a max of',as.character(max_models),'models across all features.'))
    if(max_models>10000000){
      print('Warning: a run at this scale (over 10 million models fit) may take a long time.')
      Sys.sleep(2)
    }
    print('Checking sample IDs...')
    ind_sampids=purrr::map(independent_variables, function(x) x %>% dplyr::select(colnames(x)[1]))
    dep_sampids=purrr::map(dependent_variables, function(x) x %>% dplyr::select(colnames(x)[1]))
  #  if(unique(unlist(unname(purrr::map(seq(length(ind_sampids)), function(x) unique(ind_sampids[[x]]==dep_sampids[[x]])))))!=TRUE){
  #    print('Looks like between your independent and dependent variables you have either differing number of samples, your sample IDs are of different types, or you do not have a 1 to 1 sampleID mapping between the two dataframes. Please examine your data and try again.')
  #    quit()
   # }
    print('Checking for illegal variable names...')
    illegal_names = c('dependent_variables','independent_variables','feature','max_vibration_num','fdr_method','fdr_cutoff','primary_variable','independent_feature')
    allnames=unique(unname(unlist(c(purrr::map(dependent_variables, function(x) colnames(x)), purrr::map(independent_variables, function(x) colnames(x))))))
    to_change = intersect(illegal_names,allnames)
  }
  else{
    num_features = ncol(dependent_variables) - 1
    num_samples = nrow(dependent_variables) - 1
    num_ind = ncol(independent_variables) - 1
    data_summary = dplyr::bind_cols(list('feature_num' = unlist(unname(num_features)),'sample_num' = unlist(unname(num_samples)),'adjuster_num' = unlist(unname(num_ind)))) %>% dplyr::mutate(dataset=seq_along(num_features))
    print(paste('Preparing to run VoE pipeline for',as.character(num_features),'features,',as.character(num_samples),'samples, and',as.character(num_ind),'adjusters.'))
    print(paste('Model type: ',model_type,sep=''))
    print(paste('Family: ',family[[1]],sep=''))
    print(paste('Primary variable of interest: ',primary_variable,sep=''))
    print(paste('FDR method: ',fdr_method,sep=''))
    print(paste('FDR cutoff: ',as.character(fdr_cutoff),sep=''))
    print(paste('Only keeping features that are at least',proportion_cutoff*100,'percent nonzero.'))
    print(paste('Max number of vibrations (if vibrate=TRUE): ',as.character(max_vibration_num),sep=''))
    print(paste('Max number of independent features per vibration (if vibrate=TRUE): ',as.character(max_vars_in_model),sep=''))
    max_models_per_feature = num_ind*max_vibration_num
    max_models = num_features*max_models_per_feature
    print(paste('This works out to a max of',as.character(max_models),'models across all features.'))
    if(max_models>10000000){
      print('Warning: a run at this scale (over 10 million models fit) may take a long time. If you\'re running this interactively, we recommend splitting your input features into batches or using our command line tool.')
      Sys.sleep(2)
    }
    print('Checking sample IDs...')
    ind_sampids=independent_variables[,1]
    dep_sampids=dependent_variables[,1]
    if(all.equal(ind_sampids,dep_sampids)==FALSE){
      print('Looks like between your independent and dependent variables you have either differing number of samples, your sample IDs are of different types, or you do not have a 1 to 1 sampleID mapping between the two dataframes. Please examine your data and try again.')
      quit()
    }
  print('Checking for illegal variable names...')
  illegal_names = c('dependent_variables','independent_variables','feature','max_vibration_num','fdr_method','fdr_cutoff','primary_variable','independent_feature')
  allnames=c(colnames(dependent_variables),colnames(independent_variables))
  to_change = intersect(illegal_names,allnames)
  }
  if(length(to_change)>0){
    print('Illegal variable names that may disrupt pipeline have been identified. Please adjust the following column names in your input data.')
    print(to_change)
    return(FALSE)
  }
  else{
    print('Pre-flight checks complete, you\'re ready to go.')
    return(TRUE)
  }
}
