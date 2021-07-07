#create merged data frames for benchmarking

library(tidyverse)

b=readRDS('nhanes_ldl_dep.rds')

c=readRDS('nhanes_sysbp_dep.rds')

d=readRDS('nhanes_tc_dep.rds')

f=readRDS('nhanes_ldl_ind.rds')


bc = left_join(b,c) %>% filter(!is.na(SYSBP))
abc = left_join(bc,d) %>% filter(!is.na(LBDTCSI))

f = f %>% filter(SEQN %in% abc$SEQN) %>% select(-c(SYSBP,LBDTCSI))
bc = bc %>% filter(SEQN %in% f$SEQN)
abc = abc %>% filter(SEQN %in% f$SEQN)

saveRDS(bc,'nhanes_2_dep_benchmark.rds')
saveRDS(abc,'nhanes_3_dep_benchmark.rds')
saveRDS(f,'nhanes_ldl_ind_benchmark.rds')
