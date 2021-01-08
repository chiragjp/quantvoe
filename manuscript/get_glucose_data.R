library(tidyverse)

full = readRDS('all_raw_nhanes_data.rds')

scrip_survey_years  = c("2011-2012" ,"2013-2014","2015-2016" ,"2017-2018")

full = full %>% filter(cycle %in% scrip_survey_years)

#load prescription data
scrip = readRDS('nhanes_merged_mort_2015_prescription_2011_2018_11082020.rds') %>% select(SEQN,flag_METFORMIN)

#remove columns predominantly NA and missing values for variables of interest
full = list(full,scrip) %>% reduce(left_join)
full$flag_METFORMIN[is.na(full$flag_METFORMIN)] = 0

full_subset = full %>% filter(!is.na(LBDGLUSI),!is.na(flag_METFORMIN) | !is.na(INDFMMPI))
toremove = which(colSums(is.na(full_subset))/nrow(full_subset)>=.5)
full_subset = full_subset %>% select(-c(names(toremove)))

#load master data dictionary and subset to relevant columns
all_vars = read.csv('dataDictionary_NHANES.csv')
all_vars_subset = all_vars %>% filter(Variable.Name %in% colnames(full_subset)) %>% select(Variable.Name,Variable.Description) %>% distinct

#write data dict subset to file and manually determine if vars will be included or not
write.csv(all_vars_subset,'./temp_glucose.csv')

#load in list of (now manually curated) variables to be removed due to redudancy or lack of relevance
toremove2=read.csv('redundant_not_needed_vague.csv') %>% unlist %>% unname

#write final data to file for analysis
weighting = readRDS('nhanes_merged_mort_2015_prescription_2011_2018_11082020.rds') %>% select(SEQN,WTSAF2YR,SDMVPSU,SDMVSTRA)
weighting$WTSAF2YR[weighting$WTSAF2YR==0]=NA
full_subset = full_subset %>% select(-all_of(colnames(full_subset)[colnames(full_subset) %in% toremove2]),-starts_with('WT'),-SDMVPSU,-SDMVSTRA)
countframe = map(full_subset, function(x) length(unique(na.omit(x)))) %>% data.frame %>% t()
binvals = rownames(countframe)[countframe==2]
full_subset_binary = full_subset %>% select(SEQN,all_of(binvals))
full_subset = full_subset %>% select(-all_of(binvals)) %>% mutate(SEQN = as.character(SEQN)) %>% mutate_if(is.numeric,scale) %>% mutate(SEQN = as.numeric(SEQN))
full_subset = left_join(full_subset,weighting)
full_subset = left_join(full_subset,full_subset_binary)
full_subset = full_subset %>% filter(!is.na(WTSAF2YR))
full_subset_dep = full_subset %>% select(SEQN,LBDGLUSI)
full_subset_ind = full_subset %>% select(-c(LBDGLUSI))

saveRDS(full_subset_dep,'nhanes_glu_dep.rds')
saveRDS(full_subset_ind,'nhanes_glu_ind.rds')







