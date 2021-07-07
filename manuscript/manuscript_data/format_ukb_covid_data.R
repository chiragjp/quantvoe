#format UKB data for covid voe

library(tidyverse)

data = readRDS('COVID_data.rds') %>% select(-Age_squared) %>% rename(covid_positive_status=result)
toremove = which(colSums(is.na(data))/nrow(data)>=.5)
data_filtered= data %>% select(-c(names(toremove))) 
data_filtered = data_filtered %>% filter(!is.na(covid_positive_status),!is.na(INT_median_30890))


countframe = map(data_filtered, function(x) length(unique(na.omit(x)))) %>% data.frame %>% t()
binvals = rownames(countframe)[countframe==2]
data_filtered_binary = data_filtered %>% select(eid,all_of(binvals))
data_filtered = data_filtered %>% select(-all_of(binvals)) %>% mutate(eid = as.character(eid)) %>% mutate_if(is.numeric,scale) %>% mutate(eid = as.numeric(eid))
data_filtered = left_join(data_filtered,data_filtered_binary)
dep_data = data_filtered %>% select(eid,covid_positive_status,covid_hosp_status)
ind_data = data_filtered %>% select(-covid_positive_status,-covid_hosp_status)

saveRDS(dep_data,'covid_ukb_depdata.rds')
saveRDS(ind_data,'covid_ukb_inddata.rds')