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

