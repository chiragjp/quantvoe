# quantvoe: Evaluating association robustness though vibration of effects

## Introduction

When computing any association between an X and a Y variable -- like coffee and heart attacks, 
wine and mortality, or weight and type 2 diabetes onset, different modeling strategies can 
often yield different or even conflicting results. We refer to this as "vibration of effects," 
and it permeates any field that uses observational data (which is most fields). Modeling vibration 
of effects allows researchers to figure out what the most robust and reliable associations are, 
which is ensuring our models are actually useful. We built this package to measure 
vibration of effects, fitting hundreds, thousands, potentially millions of models to show 
exactly how consistent an association output is. quantvoe can be used for everything from 
clinical to economic data to tackle this problem, moving observational data science towards 
consistent reproducibility.

## Theory

The goal of modeling VoE is to use linear modeling to explore, in detail, every way you can model 
a single correlation. When you a model "adjust" by different variables, the initial association 
you're looking at can change. For example if you fit the following models in an attempt to explore 
physical activity and cholesterol levels. We'll refer to physical activity as the "primary variable" and total cholesterol as 
the "dependent variable."

```
bone_density ~ calcium_intake + age + sex + Vitamin_B12_intake

bone_density ~ calcium_intake + age + sex + phosphorous_intake

``` 

You might hypothesize that bone_density would have some association, either negative or positive, with calcium intake (i.e. does milk build strong bones?). It turns out you can actually see either relationship depending on how you look at it -- a statistically significant and negative one in the first model, a significant positive one in the second. This kind of result indicates a confounded (and potentially clinically/biologically interesting) relationship between bone density, calcium intake, and these other dietary variables.

"quantvoe" executes this approach process at massive scale, fitting (up to) every possible model given as set of adjusting variables, determining 1) how the association between your primary variable and dependent variable changes and 2) what the adjusters that appear to drive the change are. You end up with a plot like the one below, where each point represents a model and (the y-values are p-values, the x values are the effect size of the association between physical activity and total cholesterol, and the line represents statistical significance). 

<img src="https://github.com/chiragjp/quantvoe/blob/main/images/FIG2_voe_examples.png" width = "300" height = "300">

As you can see, you could potentially see a positive or negative statistically significant correlation depending on the model you fit. Most studies will only fit one model, potentially obscuring this kind of result.

To learn more about vibration of effects, take a look at:

* https://www.chiragjpgroup.org/voe/
* https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4555355/
* https://academic.oup.com/ije/advance-article/doi/10.1093/ije/dyaa164/5956264

### Algorithmic overview

![VoE pipeline](../main/images/FIG_overview.png)

A) VoE takes three types of input data, all in the form of pairs of dataframes, either at the command line or in an interactive R session: 1) a single dependent variable and multiple independent variables, 2) multiple dependent variables, or 3) multiple datasets. The first column of the independent AND dependent dataframes must correspond to subject of sample IDs, and the independent dataframe must also contain a column corresponding to the primary variable of interest. In the event that the user passes multiple datasets (with a independent and dependent variable dataframe for each one), a meta-analysis will be run as part of the initial association step. 

B) There are 4 main steps -- checking the input data, computing initial univariate associations, computing vibrations across possible adjusters, and quantifying how adjuster presence/absence correlates to changes in the primary association of interest. Any linear model family implemented by R's glm function can be specified in addition to negative binomial models. The pipeline can also handle survey-weighted regression.

The last step involves fitting the following model:

```
absolute_value(coefficient_on_primary_variable) ~ adjuster_1 + ... + adjuster_n + (1|dependent_feature) 
```

Where the y variable is the coefficient on the primary_variable for each vibration, and the adjuster_n variables correspond to the presence/absence of each adjusting variable in a given model. The random effect, which is only present if multiple dependent_features are analyzed, is present to account for variable in model effect size as a function of having multiple assocations of interest with the primary variable.

## Installation

We recommend building from the Git repo so you can easily access and use the command-line script (voe_command_line_deployment.R) in the root directory. Note that the command line implementation requires the "optparse" library, which can be installed with `install.packages("optparse")` at the R terminal.

```
git clone https://github.com/chiragjp/quantvoe.git
R CMD build /path/to/quantvoe/repository/
R CMD install quantvoe_0.1.0.tar.gz
```

To install the most recent development version without cloning, use R's devtools package:
```
#if devtools is not already installed, do so with install.packages() from the R terminal
install.packages('devtools')
devtools::install_github("chiragjp/quantvoe")
```

You can alternatively download the [mosts recent release](https://github.com/chiragjp/quantvoe/releases) tarball and install it locally with R CMD install or devtools.

We are in the process of submitting to CRAN, and expect it to be accessible 
through `install.packages('quantvoe')` shortly.


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
| constant_adjusters    |  -j  | Comma-separated (no spaces) list of adjusters to include in every model. Should correspond to column names in your independent data (Default = NULL)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | No       |
| output                |  -o  | Path to and name of output .rds file (e.g. ./output.rds) .                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Yes       |
| fdr_method            |  -m  | Your choice of method for adjusting p-values. Options are BY   (default), BH, or bonferroni. Adjustment is computed for all initial, single   variable, associations across all dependent features.                                                                                                                                                                                                                                                                                                                                                                                | No        |
| fdr_cutoff            |  -c  | Cutoff for an FDR significant association. All features with   adjusted p-values initially under this value will be selected for vibrations.   (default = 0.05). Setting a stringent FDR cutoff is mostly relevant when you   are using a large number of dependent variables (eg >50) and want to   filter those with weak initial associations.                                                                                                                                                                                                                                  | No        |
| proportion_cutoff     |  -g  | A float between 0 and 1. Setting this filters out dependent   features that are this proportion of zeros or more (default = 1, so no   filtering will be done.)                                                                                                                                                                                                                                                                                                                                                                                                                    | No        |
| vibrate               |  -b  | TRUE/FALSE -- run vibrations (default = TRUE).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | No        |
| max_vars_in_model     |  -r  | Maximum number of variables allowed in a single fit in vibrations. In case an individual has many hundreds of metadata features, this prevents models from being fit with excessive numbers of variables. Modifying this parameter will change runtime for large datasets. For example, just computing all possible models for 100 variables is extremely slow. (default = 20)   | No        |
| max_vibration_num     |  -n  | Maximum number of vibrations allowed for a single dependent   variable. Setting this will also reduce runtime by reducing the number of   models fit. (default = 10,000)                                                                                                                                                                                                                                                                                                                                                                                                           | No        |
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

All of these examples can be run using the files in the [data folder](https://github.com/chiragjp/quantvoe/tree/main/data). For a more in-depth example that that explores the pipeline output, check out our package [vignette](https://github.com/chiragjp/quantvoe/tree/main/vignettes)

### Beginner

Compute VoE for the association between systolic blood pressure and physical activity with 100 vibrations, an FDR cutoff of 1 (forcing vibrations to be computed regardless of significance in initial association) and otherwise the default settings.

```
Rscript voe_command_line_deployment.R -d inst/extdata/example_data_dataset_1_dependent_systolic.rds -i inst/extdata/example_data_dataset_1_independent.rds -v physical_activity -o nhanes_voe_sysbp_physact.rds -n 1 -c 1

```

### Intermediate

Compute VoE for multiple dependent variables (BMI and blood pressure + BMI and physical activity) with customized parameters: 100 vibrations per dependent variable, 2 cores, max of 10 variables per model, FDR cutoff of 1 (which will result in vibrating over all initial association output, regardless of significance).


```
Rscript voe_command_line_deployment.R -d inst/extdata/example_data_dataset_1_dependent_systolic_bmi.rds -i inst/extdata/example_data_dataset_1_independent.rds -v physical_activity -o nhanes_voe_sysbp_bmi_physact.rds -c 1 -n 100 -r 10 -t 2

```

### Meta-analytic madman

Compute VoE for multiple dependent variables (BMI and blood pressure + BMI and physical activity) and physical activity with across multiple datasets with custom parameters and survey weighting: 100 vibrations per dependent variable, 4 cores, max of 10 variables per model, FDR cutoff of 1 (vibrate over all initial association output).


```
Rscript voe_command_line_deployment.R -d data/example_data_dataset_1_dependent_systolic_bmi.rds,inst/extdata/example_data_dataset_2_dependent_systolic_bmi.rds -i data/example_data_dataset_1_independent.rds,inst/extdata/example_data_dataset_2_independent.rds -v physical_activity -o nhanes_voe_sysbp_bmi_physact_meta_analysis.rds -c 1 -n 100 -r 10 -t 4 -w WTMEC2YR -y TRUE -k SDMVPSU -s SDMVSTRA -q TRUE -u survey -a TRUE

```
    
## FAQ

Common questions or issues will be put here for easy reference.

### How many vibrations should I do?

We've found that an adjuster needs to be seen about 1000 times before you can consistently identify its impact on a given association.

### Optimizing runtime and parameters for a given dataset

The number of vibrations, number of dependent variables, number of independent variables, max number of adjusters present in a given model, and multithreading can all affect runtime and results. A safe bet is to use the defaults (20 adjusters per vibration) and to batch your work (e.g. run the pipeline multiple times, once for each dependent variable). Below is a plot of runtimes and memory usage, comparing a standard linear model (using glm) vs survey-adjusted regression, for ~340 adjusters, 5000 individuals, and 20 cores:

![performance](../main/images/FIG_perf.png)

### Understanding the confounding analysis   

We use a regression-based approach to analyze measured confounding in VoE. Specifically, we aim to analyze how the presence -- or absence -- of different adjusting variables correlates to changes in the association between your primary variable and dependent variable(s) of interest. By default, we compute a mixed effects model across all your vibration output for your given dependent variables and primary variable. This means that if you pass multiple dependent variables, you will end up with how ALL associations change as as function of adjuster presence or absence. If you are interested in just how adjusters affect 1 dependent ~ primary variable association, you will need to rerun the analysis yourself using the R terminal (the find_confounders_linear() function on your raw vibration_data dataframe) or structure your input data such that it only has one dependent variable. Naturally, if you do only have 1 dependent variable, the program will not include a random effect.

Because we are using a regression analysis to look at the impact of adjusting variables, you are subject to any of the issues that could come with mixed effect (or plain linear) regression. Pay attention to the output to look for convergence warnings. If you still have questions, feel free to contact the authors or look at the package vignette.

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
* ggplot2
* lmerTest
* cowplot

### Additional command line requirements (must be installed manually)

* optparse

# License

[MIT](https://github.com/chiragjp/quantvoe/blob/main/LICENSE)

# Author

* Braden T Tierney
* Web: https://www.bradentierney.com/
* Twitter: https://twitter.com/BradenTierney
* LinkedIn: https://www.linkedin.com/in/bradentierney/
* Scholar: https://scholar.google.com/citations?user=6oSRYqMAAAAJ&hl=en&authuser=1&oi=ao

