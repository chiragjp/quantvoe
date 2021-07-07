#!/bin/bash

basename=$(echo $1 | cut -f1 -d,)
depfile=$(echo $1 | cut -f2 -d,)
indfile=$(echo $1 | cut -f3 -d,)
primaryvar=$(echo $1 | cut -f4 -d,)

Rscript ../../voe_command_line_deployment.R -d "$depfile" -i "$indfile" -v "$primaryvar" -j Age,f.31.0.0 -c 1 -r 20 -n 100 -g 1 -t 1 -o "$basename"_"$primaryvar"_quantvoe_output.rds -l quasibinomial
