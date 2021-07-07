library(tidyverse)
library(pheatmap)
library(reshape2)

phenotypes = unique(c('DR1TTFAT','DR1TFIBE','DR1TCAFF','DR1TCALC','MCQ300A','LBDVIASI','TOTMETW','DR1TCALC','INDFMMPI','DR1TALCO','flag_LISINOPRIL','DR1TSUGR','LBXCOT','BMXBMI','DR1TKCAL'))

files=list.files()[grep('output',list.files())]
files=files[grep('rds',files)]
files=files[-grep('_250000',files)]
files=files[-grep('-',files)]
files=files[-grep('_10_',files)]
files=files[-grep('_20_',files)]

breaksList = seq(.85, 1.0, by = .01)
cols=colorRampPalette(c("red","yellow","royalblue"))

confounder_presence_data = list()
confounder_analysis_list_melted = list()
for(p in phenotypes){
  print(p)
  files_sub = files[grep(p,files)]
  confounder_analysis_list = list()
  for(f in files_sub){
    print(f)
    data = readRDS(f)
    name = strsplit(strsplit(f,'quantvoe_output_1_')[[1]][2],'\\.')[[1]][1]
    vibration_output=data$vibration_output
    confounder_analysis=vibration_output$confounder_analysis %>% select(term,estimate)
    colnames(confounder_analysis)[2] = name
    confounder_analysis_list[[name]]=confounder_analysis
    totalobs = unlist(unname(vibration_output$data[9:ncol(vibration_output$data)] %>% colSums))
    confounder_presence_data[[f]]=c(totalobs[!is.na(totalobs)])
  }
  confounder_analysis_list = confounder_analysis_list %>% reduce(inner_join, by = "term") %>% select(-term)
  confounder_analysis_list = confounder_analysis_list[, c(1,5,8,11,2,6,9,12,3,7,10,13,4)]
  confounder_analysis_list = cor(confounder_analysis_list,use='complete.obs')
  confounder_analysis_melted = melt(confounder_analysis_list) %>% mutate(phenotype = p)
  confounder_analysis_list_melted[[p]] = confounder_analysis_melted
  write.csv(confounder_analysis_list,paste('benchmarking_corplot_data_',f,'.csv',sep=''))
  pdf(paste('benchmarking_corplot_data_',f,'.pdf',sep=''),width=5,height=5)
  pheatmap(confounder_analysis_list,cluster_rows=FALSE,cluster_cols=FALSE,breaks=breaksList,legend = TRUE,color=cols(14))
  dev.off()
}

confounder_analysis_list_melted_merged = bind_rows(confounder_analysis_list_melted) %>% group_by(Var1,Var2) %>% select(-phenotype) %>% mutate(mean = mean(value))
confounder_analysis_list_averaged = spread(confounder_analysis_list_melted_merged %>% select(-value) %>% distinct,Var1,mean)

pdf(paste('benchmarking_corplot_data.pdf',sep=''),width=5,height=5)
pheatmap(confounder_analysis_list_averaged,cluster_rows=FALSE,cluster_cols=FALSE,breaks=breaksList,legend = TRUE,color=cols(14))
dev.off()

write.csv(confounder_analysis_list_averaged,'confounder_analysis_list_averaged.csv')

num_obs_pe_var = do.call('rbind',confounder_presence_data)  %>% melt %>% mutate(num=strsplit(as.character(Var1),'_quantvoe_output_1_') %>% map_chr(2) %>% strsplit('\\.') %>% map_chr(1)) %>% select(-Var1,-Var2) %>% group_by(num) %>% summarize(mean=mean(value),sd=sd(value)) %>% mutate(num=as.numeric(num)) %>% arrange(num)
write.csv(num_obs_pe_var,'num_obs_per_var.csv')







