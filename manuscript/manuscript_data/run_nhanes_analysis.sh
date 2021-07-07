#!/bin/bash

basename=$(echo $1 | cut -f1 -d,)
depfile=$(echo $1 | cut -f2 -d,)
indfile=$(echo $1 | cut -f3 -d,)
weights=$(echo $1 | cut -f4 -d,)
primaryvar=$(echo $1 | cut -f5 -d,)

if [ "${basename}" == "vision" ]; 
	then
	 	Rscript ../../voe_command_line_deployment.R -d "$depfile" -i "$indfile" -v "$primaryvar" -j RIAGENDR,RIDAGEYR -c 1 -r 20 -n 10000 -g 1 -t 1 --ids SDMVPSU --strata SDMVSTRA --weights "$weights" -q TRUE -o "$basename"_"$primaryvar"_quantvoe_output.rds -p quasibinomial -u survey
	else
	 	Rscript ../../voe_command_line_deployment.R -d "$depfile" -i "$indfile" -v "$primaryvar" -j RIAGENDR,RIDAGEYR -c 1 -r 20 -n 10000 -g 1 -t 1 --ids SDMVPSU --strata SDMVSTRA --weights "$weights" -q TRUE -o "$basename"_"$primaryvar"_quantvoe_output.rds -u survey
fi
