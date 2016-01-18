options linesize=80;

data xv_pred;
    infile '~/ph/final/xv_pred.dat';
    input replicate date_time$ animal day silage dmi rumenph PrumenphM RrumenphM
    xv_PrumenphM xv_RrumenphM absrM PrumenphU RrumenphU xv_PrumenphU xv_RumenphU
    absrU reticph PreticphT RreticphT;
run; 

proc contents data=xv_pred;
run;
