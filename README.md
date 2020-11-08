# quantvoe: Evaluating model robustness though vibration of effects

## Introduction

When computing any association between an X and an Y variable -- like coffee and heart attacks, 
wine and mortality, or weight and type 2 diabetes onset, different modeling strategies can 
often yield different or even conflicting results. We refer to this as "vibration of effects," 
and it permeates any field that uses observational data (which is most fields). Modeling vibration 
of effects allows researchers to figure out what the most robust and reliable associations are, 
which is ensuring our models are actually useful. We built this package to measure 
vibration of effects, fitting hundreds, thousands, potentially millions of models to show 
exactly how consistent an association output is. Quant_voe can be used for everything from 
clinical to economic data to tackle this problem, moving observational data science towards 
consistent reproducibility.

## Theory

The goal of modeling VoE is to use linear modeling to explore, in detail, every way you can model 
a single correlation. When you a model "adjust" by different variables, the initial association 
you're looking at can change. For example if you fit the following models in an attempt to explore 
physical activity and BMI. We'll refer to physical activity as the "primary variable" and BMI as 
the "dependent variable."

```
body_mass_index ~ physical_activity

<other model>
``` 

We, and others, have shown that in the first equation you'll see a negative coefficient on the 
physical -- the more physical activity, the lower BMI. However, we have also shown that if you 
fit the second model you'll actually see the opposite sign coefficient -- a positive one, which 
would imply that the more you exercise, the higher your BMI will be. This kind of result indicates 
a confounded (and potentially clinically/biologically interesting) relationship between BMI, physical 
activity, and XXX.

quantvoe executes this approach process at massive scale, fitting (up to) every possible model given 
as set of "adjusters" (like adjuster 1 and adjuster 2 above), determining 1) how the association 
between your primary variable and dependent variable changes and 2) what the adjusters that appear 
to drive the change are.

To learn more about vibration of effects, take a look at:

https://www.chiragjpgroup.org/voe/
https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4555355/
https://academic.oup.com/ije/advance-article/doi/10.1093/ije/dyaa164/5956264

### Overview of the algorithmic approach. 

![VoE pipeline](../main/images/FIG_overview.png)

A) VoE takes three types of input data, all in the form of pairs of dataframes, either at the command line or in an interactive R session: 1) a single dependent variable and multiple independent variables, 2) multiple dependent variables, or 3) multiple datasets. The first column of the independent AND dependent dataframes must correspond to subject of sample IDs, and the independent dataframe must also contain a column corresponding to the primary variable of interest. In the event that the user passes multiple datasets (with a independent and dependent variable dataframe for each one), a meta-analysis will be run as part of the initial association step. 

B) There are 4 main steps -- checking the input data, computing initial univariate associations, computing vibrations across possible adjusters, and quantifying how adjuster presence/absence correlates to changes in the primary association of interest. 

## Installation

To install the most recent development version, install and use R's devtools package:
```
#if devtools is not already installed, do so with install.packages()
install.packages('devtools')
devtools::install_github("chiragjp/quantvoe")
```
To build from source:

```
git clone https://github.com/chiragjp/quantvoe.git
R CMD build /path/to/quantvoe/repository/
R CMD install quantvoe_0.1.0.tar.gz
```

We are in the process of submitting to CRAN, and expect it to be accessible 
through `install.packages('quantvoe')` shortly.

## Usage 

### Command line

For large analyses where you want to run our pipeline from end-to-end (raw data input, initial associations, vibrations, and analysis of vibrations), we recommend you use our command line implementation. The script we use to run this is in the root directory of our Github repository. It can be downloaded manually or cloned with the repo itself during the build process. It has the same options (see below) as the R terminal implementation, with the key differences being that you need to point it to saved .rds files containing your independent and dependent variables and additionally specify an output location/filename.

### R terminal

If you are interested in running just a component of our pipeline (e.g. vibrations only), you can use the R terminal to access the requisite specific functions, each of which has particular input requirements described in the R documentation. 

### Options

|     Name              | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | Required? |   |   |
|-----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------|---|---|
| dependent_variables   | A tibble containing the information for your dependent variables   (e.g. bacteria relative abundance, age). The columns should correspond to   different variables, and the rows should correspond to different units, such   as individuals (e.g. individual1, individual2, etc). If passing multiple   datasets, pass a named list of the same length and in the same order as the   independent_variables parameter. If running from the command line, pass the   path (or comma separated paths) to .rds files containing the data, one per   dataset. | Yes       |   |   |
| independent_variables | A tibble containing the information for your independent variables   (e.g. bacteria relative abundance, age). The columns should correspond to   different variables, and the rows should correspond to different units,    (e.g. individual1, individual2, etc). If passing multiple datasets, pass a   named list of the same length and in the same order as the   dependent_variables parameter. If running from the command line, pass the   path (or comma separated paths) to .rds files containing the data, one per   dataset.                    | Yes       |   |   |
| primary_variable      | The primary independent variable of interest.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | Yes       |   |   |
| fdr_method            | Your choice of method for adjusting p-values. Options are BY   (default), BH, or bonferroni. Adjustment is computed for all initial, single   variable, associations across all dependent features.                                                                                                                                                                                                                                                                                                                                                        | No        |   |   |
| fdr_cutoff            | Cutoff for an FDR significant association. All features with   adjusted p-values initially under this value will be selected for vibrations.   (default = 0.05). Setting a stringent FDR cutoff is mostly relevant when you   are using a large number of dependent variables (eg >50) and want to   filter those with weak initial associations.                                                                                                                                                                                                          | No        |   |   |
| proportion_cutoff     | A float between 0 and 1. Setting this filters out dependent   features that are this proportion of zeros or more (default = 1, so no   filtering will be done.)                                                                                                                                                                                                                                                                                                                                                                                            | No        |   |   |
| vibrate               | TRUE/FALSE -- run vibrations (default = TRUE).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | No        |   |   |
| max_vars_in_model     | Maximum number of variables allowed in a single fit in vibrations.   In case an individual has many hundreds of metadata features, this prevents   models from being fit with excessive numbers of variables. Setting this   parameter will improve runtime for large datasets. (default=NULL)                                                                                                                                                                                                                                                             | No        |   |   |
| max_vibration_num     | Maximum number of vibrations allowed for a single dependent   variable. Setting this will also reduce runtime by reducing the number of   models fit. (default = 10,000)                                                                                                                                                                                                                                                                                                                                                                                   | No        |   |   |
| meta_analysis         | TRUE/FALSE -- indicates if computing meta-analysis across multiple   datasets. Set to TRUE by default if the pipeline detects multiple datasets.   Setting this variable to TRUE but providing one dataset will throw an error.                                                                                                                                                                                                                                                                                                                            | No        |   |   |
| model_type            | Specifies regression type -- "glm", "survey",   or "negative_binomial". Survey regression will require additional   parameters (at least weight, nest, strata, and ids). Any model family (e.g.   gaussian()), or any other parameter can be passed as the family argument to   this function.                                                                                                                                                                                                                                                             | No        |   |   |
| family                | GLM family (default = gaussian()). For help see help(glm) or   help(family).                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | No        |   |   |
| ids                   | Name of column in dataframe specifying cluster ids from largest   level to smallest level. Only relevant for survey data. (Default = NULL).]                                                                                                                                                                                                                                                                                                                                                                                                               | No        |   |   |
| strata                | Name of column in dataframe with strata. Relevant for survey data.   (Default = NULL).                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | No        |   |   |
| weights               | Name of column containing sampling weights.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | No        |   |   |
| nest                  | If TRUE, relabel cluster ids to enforce nesting within strata.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | No        |   |   |
| cores                 | Number of cores to use for vibration (default = 1).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | No        |   |   |
| confounder_analysis   | TRUE/FALSE -- run mixed effect confounder analysis (default=TRUE).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | No        |   |   |

## Usage (R terminal)


## Output

VoE

| Inputs | 
| --------- | ----------- |
|  |  |
|  |  |
|  |  |
|  |  |
| Options  |
| --------- | ----------- |
|  |  |
|  |  |
|  |  |
|  |  |

## Testing

    
## FAQ


## Bugs

Submit any issues, questions, or feature requests to the [Issue Tracker](https://github.com/chiragjp/quantvoe/issues).

## Citation



## Dependencies

### Mandatory

# Licence

[MIT](https://github.com/chiragjp/quantvoe/blob/main/LICENSE)

## Author

* Braden Tierney
* Web: 
* LinkedIn: 
* Twitter: 
* Scholar: 

