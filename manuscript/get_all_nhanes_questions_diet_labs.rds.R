library(RNHANES)
library(tidyverse)

download_bulk <- function(data_file_names, data_file_years) {
  data_frames <- vector("list", length = length(data_file_names))
  safely_nhanes_load_data <- safely(nhanes_load_data)
  for(rw in 1:(length(data_file_names))) {
    cat(sprintf('%i/%i\n', rw, length(data_file_names)))
    data_frames[[rw]] <- safely_nhanes_load_data(data_file_names[rw], data_file_years[rw])  
  }
  return(data_frames)
}

merge_data <- function(merged_data,dataset){
  column_mapping = bind_rows(map(seq(length(dataset)), function(x) data.frame(x,colnames(dataset[[x]])))) %>% rename(col = "colnames.dataset..x...") %>% filter(col!='file_name',col!='end_year',col!='begin_year',col!='cycle',col!='SEQN')
  all_colnames = unlist(unname(unique(column_mapping$col)))
  for(c in all_colnames){
    skiploop=FALSE
    column_mapping_sub = column_mapping %>% filter(col == c)
    index_values = unlist(unname(column_mapping_sub$x))
    datasets_of_interest = map(index_values, function(x) dataset[[x]])
    #if(!('SEQN' %in% unique(unlist(unname(map(datasets_of_interest,function(x) colnames(x))))))){
    # next
    #}
    tryCatch({
      datasets_of_interest = map(datasets_of_interest, function(x) x %>% select(SEQN,cycle,c))
    },
    error=function(e){
      skiploop <<- TRUE
    })
    if(skiploop){
      next
    }
    types = unlist(unname(map(datasets_of_interest, function(x) x %>% select(c) %>% unlist %>% unname %>% typeof)))
    if(length(unique(types)) == 1){
      dataset_sub = bind_rows(datasets_of_interest)
      if(length(dataset_sub$SEQN)==length(unique(dataset_sub$SEQN))){
        merged_data = left_join(merged_data,dataset_sub)
      }
    } 
  }
  return(merged_data)
}

survey_years  = c("2003-2004", "2005-2006", "2007-2008", "2009-2010" ,"2011-2012" ,"2013-2014","2015-2016" ,"2017-2018")

demo_vars <- nhanes_variables(components="demographics")
lab_vars <- nhanes_variables(components="laboratory")
dietary_vars <- nhanes_variables(components="dietary")
question_vars <- nhanes_variables(components="questionnaire")
exam_vars <- nhanes_variables(components="examination") %>% filter( variable_name == 'BPXSY1' | variable_name == 'BPXSY2' | variable_name == 'BPXSY3'| data_file_description == 'Body Measures'| variable_name ==  'VIDLVA' | variable_name == 'VIDRVA' | variable_name == 'DXXOFBMD')
exam_vars_names = exam_vars %>% select(variable_name) %>% distinct %>% unlist %>% unname

#aquire raw data
demos <- download_bulk(rep('DEMO', length(survey_years)), survey_years)
demos = map(demos, function(x) x[[1]])
merged_data_demos = bind_rows(demos) 

saveRDS(demos,'nhanes_all_demos.rds')

lab_filename_cycle <- lab_vars %>% select(data_file_name, cycle) %>% unique()
labs <- download_bulk(lab_filename_cycle$data_file_name, lab_filename_cycle$cycle)
labs = map(labs, function(x) x[[1]])
labs = labs[lengths(labs) != 0]

saveRDS(labs,'nhanes_all_labs.rds')

question_filename_cycle <- question_vars %>% select(data_file_name, cycle) %>% unique()
questions <- download_bulk(question_filename_cycle$data_file_name, question_filename_cycle$cycle)
questions = map(questions, function(x) x[[1]])
questions = questions[lengths(questions) != 0]

saveRDS(questions,'nhanes_all_questions.rds')

dietary_filename_cycle <- dietary_vars %>% select(data_file_name, cycle) %>% unique()
dietary <- download_bulk(dietary_filename_cycle$data_file_name, dietary_filename_cycle$cycle)
dietary = map(dietary, function(x) x[[1]])
dietary = dietary[lengths(dietary) != 0]

saveRDS(dietary,'nhanes_all_dietary.rds')

exam_filename_cycle <- exam_vars %>% select(data_file_name, cycle) %>% unique()
exam <- download_bulk(exam_filename_cycle$data_file_name, exam_filename_cycle$cycle)
exam = map(exam, function(x) x[[1]])
exam = exam[lengths(exam) != 0]

saveRDS(exam,'nhanes_exams_subset_for_analysis.rds')

#merge acquired data
merged_data_labs = merge_data(merged_data_demos,labs)
merged_data_exams = merge_data(merged_data_demos,exam)
temp = merged_data_exams %>% select(SEQN,BPXSY1,BPXSY2,BPXSY3) %>% mutate(SYSBP = rowMeans(select(merged_data_exams,BPXSY1,BPXSY2,BPXSY3),na.rm=TRUE)) %>% select(-BPXSY1,-BPXSY2,-BPXSY3)
merged_data_exams = left_join(merged_data_exams,temp) %>% select(all_of(intersect(exam_vars_names,colnames(merged_data_exams))),SYSBP)
merged_data_questions = merge_data(merged_data_demos,questions)
merged_data_dietary = merge_data(merged_data_demos,dietary) %>% select(SEQN,cycle,starts_with('DR1T'),starts_with('FFQ'),starts_with('DTD'))

#merge all data together
full = list(merged_data_dietary,merged_data_labs,merged_data_questions,merged_data_exams) %>% reduce(left_join)

#using master data dictionary, force columns to correct type and, for each column non factor annotated as having missing values, replace missin value indicators with NAs
all_vars = read.csv('dataDictionary_NHANES.csv')
all_vars = all_vars %>% filter(Variable.Name %in% colnames(full))

factor_vars = all_vars %>% filter(is_categorical==1) %>% select(Variable.Name) %>% unique %>% unlist %>% unname
full[factor_vars] <- lapply(full[factor_vars], factor) 

#for numeric columns with indicators for missing data (e.g. no response), replace with NA
valuestorecode = c('Could not obtain','missing','Missing',"Don't know",'Refused','SP refused','No response','Cannot be assessed','Calculation cannot be determined','Non-Respondent','No Lab Result','More than 1 year unspecified')

recode_table = all_vars %>% filter(is_categorical==0) %>% select(Variable.Name,Value.Description,Code.or.Value) %>% filter(Value.Description %in% valuestorecode) %>% distinct
for(val in unique(recode_table$Variable.Name)){
  recode_table_sub = recode_table %>% filter(Variable.Name==val)
  for(val2 in recode_table_sub$Value.Description){
    full[,val][full[,val]==val2]=NA
  }
}

saveRDS(full,'all_raw_nhanes_data.rds')











