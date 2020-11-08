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

### Overview of the algorithmic approach

![VoE pipeline](../main/images/FIG_overview.png)

A) VoE takes three types of input data, all in the form of pairs of dataframes, either at the command line or in an interactive R session: 1) a single dependent variable and multiple independent variables, 2) multiple dependent variables, or 3) multiple datasets. The first column of the independent AND dependent dataframes must correspond to subject of sample IDs, and the independent dataframe must also contain a column corresponding to the primary variable of interest. In the event that the user passes multiple datasets (with a independent and dependent variable dataframe for each one), a meta-analysis will be run as part of the initial association step. 

B) There are 4 main steps -- checking the input data, computing initial univariate associations, computing vibrations across possible adjusters, and quantifying how adjuster presence/absence correlates to changes in the primary association of interest. Any linear model family implemented by R's glm function can be specified in addition to negative binomial models. The pipeline can also handle survey-weighted regression.

The last step involves fitting the following model:

```
absolute_value(coefficient_on_primary_variable) ~ adjuster_1 + ... + adjuster_n + (1|dependent_feature) 
```

Where the y variable is the coefficient on the primary_variable for each vibration, and the adjuster_n variables correspond to the presence/absence of each adjusting variable in a given model. The random effect, which is only present if multiple dependent_features are analyzed, is present to account for variable in model effect size as a function of having multiple assocations of interest with the primary variable.

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

Note that the command line implementation requires the "optparse" library, which can be installed with `install.packages("optparse")`.

## Usage 

### Command line

For most analyses where you want to run our pipeline from end-to-end (raw data > initial associations > vibrations > analysis of vibrations), we recommend you use our command line implementation. The script we use to run this is in the root directory of our Github repository. It can be downloaded manually or cloned with the repo itself during the build process. It is called with the `Rscript` command and has the nearly identical options as the R terminal function `full_voe_pipeline()`, with the key differences being that you need to point it to saved .rds files containing your independent and dependent variables and additionally specify an output location/filename.

To display the options for the command line tool:

```
Rscript voe_command_line_deployment.R -h
```

### Command line options

|     Name              | Flag | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | Required? |
|-----------------------|------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------|
| dependent_variables   |  -d  | The path to a tibble (saved as an rds)  containing the information for your   dependent variables (e.g. bacteria relative abundance, age). The columns   should correspond to different variables, and the rows should correspond to   different units, such as individuals (e.g. individual1, individual2, etc). If   inputting multiple datasets in order to run a meta-an analyais, pass a comma   separated list of paths to the location of your saved tibbles (one per   dataset). Be sure to not include spaces in the list or commas in the   paths/filenames themselves.  | Yes       |
| independent_variables |  -i  | The path to a tibble (saved as an rds) containing the information   for your independent variables (e.g. bacteria relative abundance, age). The   columns should correspond to different variables, and the rows should   correspond to different units,  (e.g. individual1, individual2, etc). If   inputting multiple datasets in order to run a meta-an analyais, pass a comma   separated list of paths to the location of your saved tibbles (one per   dataset). Be sure to not include spaces in the list or commas in the paths/filenames   themselves.                    | Yes       |
| primary_variable      |  -v  | The primary independent variable of interest.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Yes       |
| output                |  -o  | Path to and name of output .rds file (e.g. ./output.rds) .                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Yes       |
| fdr_method            |  -m  | Your choice of method for adjusting p-values. Options are BY   (default), BH, or bonferroni. Adjustment is computed for all initial, single   variable, associations across all dependent features.                                                                                                                                                                                                                                                                                                                                                                                | No        |
| fdr_cutoff            |  -c  | Cutoff for an FDR significant association. All features with   adjusted p-values initially under this value will be selected for vibrations.   (default = 0.05). Setting a stringent FDR cutoff is mostly relevant when you   are using a large number of dependent variables (eg >50) and want to   filter those with weak initial associations.                                                                                                                                                                                                                                  | No        |
| proportion_cutoff     |  -g  | A float between 0 and 1. Setting this filters out dependent   features that are this proportion of zeros or more (default = 1, so no   filtering will be done.)                                                                                                                                                                                                                                                                                                                                                                                                                    | No        |
| vibrate               |  -b  | TRUE/FALSE -- run vibrations (default = TRUE).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | No        |
| max_vars_in_model     |  -r  | Maximum number of variables allowed in a single fit in vibrations.   In case an individual has many hundreds of metadata features, this prevents   models from being fit with excessive numbers of variables. Setting this   parameter will improve runtime for large datasets. (default=NULL)                                                                                                                                                                                                                                                                                     | No        |
| max_vibration_num     |  -r  | Maximum number of vibrations allowed for a single dependent   variable. Setting this will also reduce runtime by reducing the number of   models fit. (default = 10,000)                                                                                                                                                                                                                                                                                                                                                                                                           | No        |
| meta_analysis         |  -a  | TRUE/FALSE -- indicates if computing meta-analysis across multiple   datasets. Set to TRUE by default if the pipeline detects multiple datasets.   Setting this variable to TRUE but providing one dataset will throw an error.                                                                                                                                                                                                                                                                                                                                                    | No        |
| model_type            |  -u  | Specifies regression type -- "glm", "survey",   or "negative_binomial". Survey regression will require additional   parameters (at least weight, nest, strata, and ids). Any model family (e.g.   gaussian()), or any other parameter can be passed as the family argument to   this function.                                                                                                                                                                                                                                                                                     | No        |
| family                |  -p  | GLM family (default = gaussian()). For help see help(glm) or   help(family).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | No        |
| ids                   |  -k  | Name of column in dataframe specifying cluster ids from largest   level to smallest level. Only relevant for survey data. (Default = NULL).]                                                                                                                                                                                                                                                                                                                                                                                                                                       | No        |
| strata                |  -s  | Name of column in dataframe with strata. Relevant for survey data.   (Default = NULL).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | No        |
| weights               |  -w  | Name of column containing sampling weights.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | No        |
| nest                  |  -q  | If TRUE, relabel cluster ids to enforce nesting within strata.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | No        |
| cores                 |  -t  | Number of cores to use for vibration (default = 1).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | No        |
| confounder_analysis   |  -y  | TRUE/FALSE -- run mixed effect confounder analysis (default=TRUE).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | No        |

### R terminal

If you are interested in running just a component of our pipeline (e.g. vibrations only), you can use the R terminal to access the requisite specific functions, each of which has particular input requirements described in the R documentation. 

## Output

Both our R terminal and command line implementations output a named list containing the following data structures:
| Name                       | Type      | Description                                                                                     | Components                  | Component description                                                                                   |
|----------------------------|-----------|-------------------------------------------------------------------------------------------------|-----------------------------|---------------------------------------------------------------------------------------------------------|
| original_data              | list      | The original dataset used in the analysis                                                       | dependent_variables         | Input dependent variable dataframe(s)                                                                   |
|                            |           |                                                                                                 | independent_variables       | Input independent variable dataframe(s)                                                                 |
|                            |           |                                                                                                 | dsid                        | Vector of dataset IDs                                                                                   |
| initial_association_output | dataframe | Output of initial, univariate   associations                                                    |                             |                                                                                                         |
| meta_analysis_output       | dataframe | If a meta-analysis was executed,   this dataframe contains the summarized meta-analytic output. |                             |                                                                                                         |
| features_to_vibrate_over   | list      | List of dependent variables that   were vibrated over                                           |                             |                                                                                                         |
| vibration_variables        | list      | List of independent adjusters used   in vibrations                                              |                             |                                                                                                         |
| vibration_output           | list      | Output of vibration and vibration analysis                                                      | summarized_vibration_output | Summary of vibration output for association(s) with primary variable. One   row per dependent variable. |
|                            |           |                                                                                                 | confounder_analysis         | Quantification of the impact of different adjusters on  association of interesst                        |
|                            |           |                                                                                                 | data                        | Raw vibration data, each row in dataframe corresponds to a different   model                            |                                                                                                     |

## Testing

Unit tests can be deployed by running the following in the R terminal after loading the package:

```
devtools::test('/path/to/package/repository')
```

or after building at the command line:

```
R CMD check /path/to/package/binary
```

## Example command-line deployments

All of these examples can be run using the files in the [data folder](XXX). For a more in-depth example that that explores the pipeline output, check out our [vignette](XXX)

### Beginner

Compute VoE for the association between BMI and systolic blood pressure with the default settings.

```

Rscript voe_command_line_deployment.R 

```

### Intermediate

Compute VoE for multiple dependent variables (BMI and blood pressure + BMI and physical activity) with customized parameters (100 vibrations per dependent variable, 2 cores, max of 10 variables per model, FDR cutoff of 1 (vibrate over all initial association output)).


```

Rscript voe_command_line_deployment.R

```


### Meta-analytic madman

Compute VoE for multiple dependent variables (BMI and blood pressure + BMI and physical activity) and physical activity with across multiple datasets with custom parameters and survey weighting (250 vibrations per dependent variable, 2 cores, max of 20 variables per model, FDR cutoff of 1 (vibrate over all initial association output)).


```

Rscript voe_command_line_deployment.R

```

    
## FAQ

Common questions or issues will be put here for easy reference.

## Bugs

Submit any issues, questions, or feature requests to the [Issue Tracker](https://github.com/chiragjp/quantvoe/issues).

## Citation



## Package requirements 

### Depends: 
* R (>= 3.5.0)

### Imports:
* dplyr
* furrr
* future
* lme4
* broom.mixed
* tibble
* purrr
* tidyr
* magrittr
* MASS
* survey
* stringr
* stats
* rlang
* meta
* broom
* rje

### Suggests: 
* testthat
* getopt
* lmerTest
* cowplot

# License

[MIT](https://github.com/chiragjp/quantvoe/blob/main/LICENSE)

# Author

* Braden T Tierney
* Web: https://www.bradentierney.com/
* Twitter: https://twitter.com/BradenTierney
* LinkedIn: https://www.linkedin.com/in/bradentierney/
* Scholar: https://scholar.google.com/citations?user=6oSRYqMAAAAJ&hl=en&authuser=1&oi=ao

