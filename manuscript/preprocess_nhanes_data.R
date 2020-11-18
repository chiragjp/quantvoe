library(tidyverse)

load('nhanes9904_VoE.Rdata')
data_filtered = mainTab %>% filter(!is.na(BMXBMI),!is.na(LBDLDL),!is.na(LBXGLU),!is.na(LBXTC),!is.na(MSYS))

toremove = which(colSums(is.na(data_filtered))/nrow(data_filtered)>=.5)
data_filtered= data_filtered %>% select(-c(names(toremove),area,bmi))  %>% mutate(sampleID=seq(nrow(data_filtered)))

data_filtered  = data_filtered %>% type.convert()

tibble_dep = data_filtered %>% select(sampleID,BMXBMI,LBDLDL,MSYS,LBXTC) 
tibble_ind = data_filtered %>% select(-c(SEQN,LBXGLU,LBDLDL,LBDLDLSI,MSYS,LBXTC,URXUMA,URXUCR,DR1TFIBE,LBXSAL,LBXSCH,LBXCBC,DR1TCALC,LBXSCR,URXUCR,LBDEONO,DR1TFDFE,LBXRBF,LBDHDL,hepa,hepb,DR1TIRON,LBXIRN,LBXSIR,LBDLYMNO,DR1TMAGN,LBDMONO,DR1TPHOS,LBXSPH,DR1TPOTA,LBXSKSI,DR1TRET,DR1TVB2,LBDNENO,DR1TSELE,DR1TVB1,LBXSCA,DR1TVARA,LBXB12,VITAMIN_B_12_mcg,VITAMIN_B_6_mg,VITAMIN_C_mg,LBXSCH,DR1TCHOL,DR1TPHOS,LBDHDL,LBXSNASI,CALCIUM_mg,DR1TFA,FOLIC_ACID_mcg,MAGNESIUM_mg,DR1TVB1,DR1TCOPP,LBXALC)) %>% relocate(sampleID)

saveRDS(tibble_dep,'nhanes_dep_data.rds')
saveRDS(tibble_ind,'nhanes_ind_data.rds')
