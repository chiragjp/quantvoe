library(tidyverse)

full = readRDS('all_raw_nhanes_data.rds')

#remove columns predominantly NA and missing values for variables of interest
full_subset = full %>% filter(!is.na(DXXOFBMD),!is.na(DR1TCALC))
toremove = which(colSums(is.na(full_subset))/nrow(full_subset)>=.5)
full_subset = full_subset %>% select(-c(names(toremove)))

#load master data dictionary and subset to relevant columns
all_vars = read.csv('dataDictionary_NHANES.csv')
all_vars_subset = all_vars %>% filter(Variable.Name %in% colnames(full_subset)) %>% select(Variable.Name,Variable.Description) %>% distinct

#write data dict subset to file and manually determine if vars will be included or not
write.csv(all_vars_subset,'./temp_bone.csv')

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
full_subset_dep = full_subset %>% select(SEQN,DXXOFBMD)
full_subset_ind = full_subset %>% select(-c(DXXOFBMD))

saveRDS(full_subset_dep,'nhanes_bone_dep.rds')
saveRDS(full_subset_ind,'nhanes_bone_ind.rds')







