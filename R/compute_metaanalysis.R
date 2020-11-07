#' Meta-analysis function
#'
#' metagen function
#' @param te estimates
#' @param sete standard errors
#' @param studlab study labels
#' @param name study labels
#' @keywords meta-analysis
#' @export
#' @importFrom dplyr %>%
meta_analysis_command <- function(te,sete,studlab,name){
return(name = list(tryCatch(meta::metagen(TE = te,seTE = sete, studlab = studlab,comb.fixed = FALSE, comb.random = TRUE, method.tau = 'REML', hakn = FALSE, prediction = TRUE,sm = "SMD",control=list(maxiter=1000)),  warning = function(w) w, error = function(e) e)))
}

#' Run meta-analysis
#'
#' Run meta-analysis for each feature
#' @param df Association output.
#' @keywords meta-analysis
#' @export
#' @importFrom rlang .data
#' @importFrom dplyr %>%
#' @importFrom rlang :=
compute_metaanalysis <- function(df) {
  new_df <- tibble::tibble(analysis = "meta-analysis") # create new tibble with placeholder column
  print('Computing meta-analysis')
  features=unique(df$feature)
  ma_output_all = list()
  for (i in seq_along(features)) {
    new_colname = features[[i]]
    df_sub = df %>% dplyr::filter(.data$feature==features[[i]])
    a=df_sub$estimate
    b=df_sub$std.error
    c=df_sub$dataset_id
    meta_analysis_output <- tibble::tibble(meta_analysis_command(a,b,c,new_colname))
    colnames(meta_analysis_output) = new_colname
    ma_output_all[[new_colname]] = meta_analysis_output
  }
  ma_output_all_df= ma_output_all %>% dplyr::bind_cols()
  return(ma_output_all_df) 
}

#' Filter-meta analysis
#'
#' Remove failed meta-analyses.
#' @param meta_df Meta-analysis output.
#' @param dataset_num Number of datasets.
#' @keywords meta-analysis
#' @importFrom rlang .data
#' @importFrom dplyr "%>%"
get_converged_metadfs <- function(meta_df,dataset_num) {
  toremove=list()
  count=0
  for(x in 1:length(meta_df)){
    if(class(meta_df[[x]][[1]])[[1]]!='metagen'){
      toremove[as.character(count)]=x
      count=count+1
      next
    }
    if(nrow(meta_df[[x]][[1]][['data']])==1){
      toremove[as.character(count)]=x
      count=count+1
    }
  }
  if(length(toremove)>0){
    meta_df=meta_df[-unname(unlist(toremove))]
  }
  return(meta_df)
}

#' Extract meta-analysis summary statistics
#'
#' Remove failed meta-analyses.
#' @param input_meta_df Meta-analysis output.
#' @param dataset_num Number of datasets.
#' @keywords meta-analysis
#' @importFrom rlang .data
#' @importFrom dplyr "%>%"
get_summary_stats <- function(input_meta_df,dataset_num) {
  meta_df=get_converged_metadfs(input_meta_df,dataset_num)
  if(ncol(input_meta_df)!=ncol(meta_df)){
    print(paste('Meta-analysis failed for',ncol(input_meta_df)-ncol(meta_df),'features or they were found in only 1 dataset. These will be dropped from your output dataframe.'))
  }
  return(
    tibble::tibble(
      feature = colnames(meta_df),
      estimate = purrr::map_dbl(meta_df, ~.[[1]]$TE.random),
      p.val = purrr::map_dbl(meta_df, ~.[[1]]$pval.random),
      bonferroni = stats::p.adjust(.data$p.val, method = "bonferroni"),
      BH = stats::p.adjust(.data$p.val, method = "fdr"),
      BY = stats::p.adjust(.data$p.val, method = "BY"),
      CI_95_lower = purrr::map_dbl(meta_df, ~.[[1]]$lower.random),
      CI_95_upper = purrr::map_dbl(meta_df, ~.[[1]]$upper.random)
    )
  )
}

#' Clean meta-analysis output and get summary statistics.
#'
#' Export meta-analysis.
#' @param metaanalysis Meta-analysis output.
#' @param dataset_num Number of datasets.
#' @keywords meta-analysis
#' @importFrom rlang .data 
#' @importFrom dplyr "%>%"
clean_metaanalysis <- function(metaanalysis,dataset_num) {
  meta_outputs <- tibble::as_tibble(metaanalysis)
  output <- get_summary_stats(meta_outputs,dataset_num)
  return(output)
}
