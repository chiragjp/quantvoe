## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)

## -----------------------------------------------------------------------------
#load required packages

library(quantvoe)
library(tidyverse)
library(ggplot2)
library(cowplot)

theme_set(theme_cowplot())

## -----------------------------------------------------------------------------
#explore vignette data after loading quantvoe package

print('Number of independent variables:')
ncol(quantvoe::independent_toy_dataset1_nhanes)-1

print('Number of dependent variables:')
ncol(quantvoe::dependent_toy_dataset1_nhanes)-1

print('Identity of dependent variables:')
colnames(dependent_toy_dataset1_nhanes)[2:3]

head(quantvoe::dependent_toy_dataset1_nhanes)
head(quantvoe::independent_toy_dataset2_nhanes)[,1:10]
head(quantvoe::dependent_toy_dataset1_nhanes)
head(quantvoe::independent_toy_dataset2_nhanes)[,1:10]


## -----------------------------------------------------------------------------

#deploy full pipeline -- this will likely take about 2-5 minutes on your local machine. 

quantvoe_output = quantvoe::full_voe_pipeline(
  dependent_variables=list('dataset1' = dependent_toy_dataset1_nhanes,'dataset2' = dependent_toy_dataset2_nhanes),
  independent_variables=list('dataset1' = independent_toy_dataset1_nhanes,'dataset2' = independent_toy_dataset2_nhanes),
  primary_variable='LBXCOT',
  meta_analysis = TRUE,
  fdr_cutoff = 1,
  max_vibration_num = 500,
  cores = 2,
  model_type = 'survey',
  ids = 'SDMVPSU',
  strata = 'SDMVSTRA',
  weights = 'WTMEC2YR',
  nest = TRUE)



#if you didn't want to run a meta-analysis, you could use the following command. It will not run in this demo because it has been commented out, and it is only here for reference.


#quantvoe::full_voe_pipeline(
#  dependent_variables=dependent_toy_dataset1_nhanes,
#  independent_variables=independent_toy_dataset1_nhanes,
#  primary_variable='LBXCOT',
#  fdr_cutoff = 1,
#  max_vibration_num = 1000,
#  cores = 2,
#  model_type = 'survey',
#  ids = 'SDMVPSU',
#  strata = 'SDMVSTRA',
#  weights = 'WTMEC2YR',
#  nest = TRUE)


## -----------------------------------------------------------------------------

#explore voe output

names(quantvoe_output)

print(quantvoe_output[['initial_association_output']])

print(quantvoe_output[['meta_analyis_output']])


## -----------------------------------------------------------------------------
vibration_output = quantvoe_output[['vibration_output']]

names(vibration_output)

vibration_output[['summarized_vibration_output']]

ggplot(data=vibration_output[['data']] %>% filter(dependent_feature=='MSYS'),aes(x=estimate,y=-log10(p.value))) + geom_hline(yintercept = -log10(.05)) + geom_point(size=.5)+ xlim(-.03, 0.03) +ylim(0,5)+ggtitle('VoE for systolic blood pressure ~ smoking')

ggplot(data=vibration_output[['data']] %>% filter(dependent_feature=='BMXBMI'),aes(x=estimate,y=-log10(p.value))) + geom_hline(yintercept = -log10(.05)) + geom_point(size=.5)+ xlim(-.03, 0.03) +ylim(0,5)+ggtitle('VoE for systolic blood pressure ~ BMI')



## -----------------------------------------------------------------------------

vibration_output[['confounder_analysis']] 

confounder_analysis_significant = vibration_output[['confounder_analysis']] %>% filter(abs(statistic)>2.5) %>% arrange(desc(estimate)) %>% filter(term!='(Intercept)')

ggplot(confounder_analysis_significant,aes(x=reorder(term,estimate),y=estimate)) +geom_bar(stat='identity',position='dodge') + xlab('') + ylab('Change in model effect size')+ggtitle('Overall confounders of BMI and blood pressure associations with smoking ')+geom_errorbar(aes(ymin =sdmin,ymax=sdmax), width = 0.2, position = position_dodge(width = 0.9))+ theme(legend.position = 'bottom',plot.title = element_text(size=12))+theme(axis.text = element_text(size=10,angle=50,hjust=1))


## -----------------------------------------------------------------------------
ggplot(data=vibration_output[['data']],aes(shape=as.factor(dependent_feature),color=as.factor(occupation),x=estimate,y=-log10(p.value))) + geom_hline(yintercept = -log10(.05)) + geom_point(size=1,alpha=.3,)+ xlim(-.03, 0.03) +ylim(0,5)+ggtitle('VoE for systolic blood pressure ~ smoking')



