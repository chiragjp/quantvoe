library(tidyverse)

indvars = c('MCQ300A' ,'DR1TFIBE','DR1TALCO','DR1TCAFF','DR1TKCAL','DR1TSUGR','DR1TTFAT','LBXCOT','TOTMETW','TVIGMETW','TMODMETW')

#####SYSBP

#load full data, clean
full = readRDS('all_raw_nhanes_data.rds')

#load physical MET data
pa = readRDS('nhanes_merged_mort_2015_prescription_2011_2018_11082020.rds') %>% select(SEQN, TOTMETW, TVIGMETW, TMODMETW)

full = left_join(full,pa)

#remove columns predominantly NA and missing values for variables of interest
full_subset = full %>% filter(!is.na(SYSBP), !is.na(MCQ300A) | !is.na(DR1TFIBE) | !is.na(DR1TALCO) | !is.na(DR1TCAFF) | !is.na(DR1TKCAL) | !is.na(DR1TSUGR) | !is.na(DR1TTFAT) | !is.na(LBXCOT) | !is.na(TOTMETW) | !is.na(TVIGMETW) | !is.na(TMODMETW))
toremove = which(colSums(is.na(full_subset))/nrow(full_subset)>=.5)
toremove = toremove[!(names(toremove) %in% indvars)]
full_subset = full_subset %>% select(-c(names(toremove)))

#load master data dictionary and subset to relevant columns
all_vars = read.csv('dataDictionary_NHANES.csv')
all_vars_subset = all_vars %>% filter(Variable.Name %in% colnames(full_subset)) %>% select(Variable.Name,Variable.Description) %>% distinct

#write data dict subset to file and manually determine if vars will be included or not
write.csv(all_vars_subset,'./temp_sysbp_exposure.csv')

#load in list of (now manually curated) variables to be removed due to redudancy or lack of relevance
toremove2=read.csv('redundant_not_needed_vague.csv') %>% unlist %>% unname

#write final data to file for analysis
weighting = full_subset %>% select(SEQN,WTMEC2YR,SDMVPSU,SDMVSTRA)
full_subset = full_subset %>% select(-all_of(colnames(full_subset)[colnames(full_subset) %in% toremove2]),-starts_with('WT'),-SDMVPSU,-SDMVSTRA)
countframe = map(full_subset, function(x) length(unique(na.omit(x)))) %>% data.frame %>% t()
binvals = rownames(countframe)[countframe==2]
full_subset_binary = full_subset %>% select(SEQN,all_of(binvals))
full_subset = full_subset %>% select(-all_of(binvals)) %>% mutate(SEQN = as.character(SEQN)) %>% mutate_if(is.numeric,scale) %>% mutate(SEQN = as.numeric(SEQN))
full_subset = left_join(full_subset,weighting)
full_subset = left_join(full_subset,full_subset_binary)
full_subset_dep = full_subset %>% select(SEQN,SYSBP)
full_subset_ind = full_subset %>% select(-c(SYSBP))

saveRDS(full_subset_dep,'nhanes_sysbp_dep.rds')
saveRDS(full_subset_ind,'nhanes_sysbp_ind.rds')

#####BMI

#remove columns predominantly NA and missing values for variables of interest
full_subset = full %>% filter(!is.na(BMXBMI), !is.na(MCQ300A) | !is.na(DR1TFIBE) | !is.na(DR1TALCO) | !is.na(DR1TCAFF) | !is.na(DR1TKCAL) | !is.na(DR1TSUGR) | !is.na(DR1TTFAT) | !is.na(LBXCOT) | !is.na(TOTMETW) | !is.na(TVIGMETW) | !is.na(TMODMETW))
toremove = which(colSums(is.na(full_subset))/nrow(full_subset)>=.5)
toremove = toremove[!(names(toremove) %in% indvars)]
full_subset = full_subset %>% select(-c(names(toremove)))

#load master data dictionary and subset to relevant columns
all_vars = read.csv('dataDictionary_NHANES.csv')
all_vars_subset = all_vars %>% filter(Variable.Name %in% colnames(full_subset)) %>% select(Variable.Name,Variable.Description) %>% distinct

#write data dict subset to file and manually determine if vars will be included or not
write.csv(all_vars_subset,'./temp_bmi_exposure.csv')

#load in list of (now manually curated) variables to be removed due to redudancy or lack of relevance
toremove2=read.csv('redundant_not_needed_vague.csv') %>% unlist %>% unname

#write final data to file for analysis
weighting = full_subset %>% select(SEQN,WTMEC2YR,SDMVPSU,SDMVSTRA)
full_subset = full_subset %>% select(-all_of(colnames(full_subset)[colnames(full_subset) %in% toremove2]),-starts_with('WT'),-SDMVPSU,-SDMVSTRA)
countframe = map(full_subset, function(x) length(unique(na.omit(x)))) %>% data.frame %>% t()
binvals = rownames(countframe)[countframe==2]
full_subset_binary = full_subset %>% select(SEQN,all_of(binvals))
full_subset = full_subset %>% select(-all_of(binvals)) %>% mutate(SEQN = as.character(SEQN)) %>% mutate_if(is.numeric,scale) %>% mutate(SEQN = as.numeric(SEQN))
full_subset = left_join(full_subset,weighting)
full_subset = left_join(full_subset,full_subset_binary)
full_subset_dep = full_subset %>% select(SEQN,BMXBMI)
full_subset_ind = full_subset %>% select(-c(BMXBMI))

saveRDS(full_subset_dep,'nhanes_bmi_dep.rds')
saveRDS(full_subset_ind,'nhanes_bmi_ind.rds')

#####TC

#remove columns predominantly NA and missing values for variables of interest
full_subset = full %>% filter(!is.na(LBDTCSI), !is.na(MCQ300A) | !is.na(DR1TFIBE) | !is.na(DR1TALCO) | !is.na(DR1TCAFF) | !is.na(DR1TKCAL) | !is.na(DR1TSUGR) | !is.na(DR1TTFAT) | !is.na(LBXCOT) | !is.na(TOTMETW) | !is.na(TVIGMETW) | !is.na(TMODMETW))
toremove = which(colSums(is.na(full_subset))/nrow(full_subset)>=.5)
toremove = toremove[!(names(toremove) %in% indvars)]
full_subset = full_subset %>% select(-c(names(toremove)))

#load master data dictionary and subset to relevant columns
all_vars = read.csv('dataDictionary_NHANES.csv')
all_vars_subset = all_vars %>% filter(Variable.Name %in% colnames(full_subset)) %>% select(Variable.Name,Variable.Description) %>% distinct

#write data dict subset to file and manually determine if vars will be included or not
write.csv(all_vars_subset,'./temp_tc_exposure.csv')

#load in list of (now manually curated) variables to be removed due to redudancy or lack of relevance
toremove2=read.csv('redundant_not_needed_vague.csv') %>% unlist %>% unname

#write final data to file for analysis
weighting = full_subset %>% select(SEQN,WTMEC2YR,SDMVPSU,SDMVSTRA)
full_subset = full_subset %>% select(-all_of(colnames(full_subset)[colnames(full_subset) %in% toremove2]),-starts_with('WT'),-SDMVPSU,-SDMVSTRA)
countframe = map(full_subset, function(x) length(unique(na.omit(x)))) %>% data.frame %>% t()
binvals = rownames(countframe)[countframe==2]
full_subset_binary = full_subset %>% select(SEQN,all_of(binvals))
full_subset = full_subset %>% select(-all_of(binvals)) %>% mutate(SEQN = as.character(SEQN)) %>% mutate_if(is.numeric,scale) %>% mutate(SEQN = as.numeric(SEQN))
full_subset = left_join(full_subset,weighting)
full_subset = left_join(full_subset,full_subset_binary)
full_subset_dep = full_subset %>% select(SEQN,LBDTCSI)
full_subset_ind = full_subset %>% select(-c(LBDTCSI))

saveRDS(full_subset_dep,'nhanes_tc_dep.rds')
saveRDS(full_subset_ind,'nhanes_tc_ind.rds')

#####LDL

#load fasting weighting data
weighting = readRDS('nhanes_merged_mort_2015_prescription_2011_2018_11082020.rds') %>% select(SEQN,WTSAF2YR,SDMVPSU,SDMVSTRA)
weighting$WTSAF2YR[weighting$WTSAF2YR==0]=NA

#remove columns predominantly NA and missing values for variables of interest
full_subset = full %>% filter(!is.na(LBDLDLSI), !is.na(MCQ300A) | !is.na(DR1TFIBE) | !is.na(DR1TALCO) | !is.na(DR1TCAFF) | !is.na(DR1TKCAL) | !is.na(DR1TSUGR) | !is.na(DR1TTFAT) | !is.na(LBXCOT) | !is.na(TOTMETW) | !is.na(TVIGMETW) | !is.na(TMODMETW))
toremove = which(colSums(is.na(full_subset))/nrow(full_subset)>=.5)
toremove = toremove[!(names(toremove) %in% indvars)]
full_subset = full_subset %>% select(-c(names(toremove)))

#load master data dictionary and subset to relevant columns
all_vars = read.csv('dataDictionary_NHANES.csv')
all_vars_subset = all_vars %>% filter(Variable.Name %in% colnames(full_subset)) %>% select(Variable.Name,Variable.Description) %>% distinct

#write data dict subset to file and manually determine if vars will be included or not
write.csv(all_vars_subset,'./temp_ldl_exposure.csv')

#load in list of (now manually curated) variables to be removed due to redudancy or lack of relevance
toremove2=read.csv('redundant_not_needed_vague.csv') %>% unlist %>% unname

#write final data to file for analysis
full_subset = full_subset %>% select(-all_of(colnames(full_subset)[colnames(full_subset) %in% toremove2]),-starts_with('WT'),-SDMVPSU,-SDMVSTRA)
countframe = map(full_subset, function(x) length(unique(na.omit(x)))) %>% data.frame %>% t()
binvals = rownames(countframe)[countframe==2]
full_subset_binary = full_subset %>% select(SEQN,all_of(binvals))
full_subset = full_subset %>% select(-all_of(binvals)) %>% mutate(SEQN = as.character(SEQN)) %>% mutate_if(is.numeric,scale) %>% mutate(SEQN = as.numeric(SEQN))
full_subset = left_join(full_subset,weighting)
full_subset = left_join(full_subset,full_subset_binary)
full_subset = full_subset %>% filter(!is.na(WTSAF2YR))
full_subset_dep = full_subset %>% select(SEQN,LBDLDLSI)
full_subset_ind = full_subset %>% select(-c(LBDLDLSI))

saveRDS(full_subset_dep,'nhanes_ldl_dep.rds')
saveRDS(full_subset_ind,'nhanes_ldl_ind.rds')

