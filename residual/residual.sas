/* residual analysis of model output */
title 'Rumen vs. Reticular pH - Analysis of Residuals';

options linesize=80;

data aormixed;
    infile '~/ph/resid/aormixed.dat';
    input animal day silage dmi time reticph retpred retresid rumenph rumpred rumresid lag1p lag3p lag2r lag4r lag7r lag9r;
    if animal = 52 and day > 12 then delete;
    timecourse = time + (day-1);

proc sort;
    by animal timecourse;
run;

proc sgplot;
    scatter x=retpred y=retresid;
    scatter x=timecourse y=retresid;
    scatter x=silage y=retresid;
    scatter x=animal y=retresid;
    scatter x=dmi y=retresid;
run;

/* significant silage effect - included as class effect in mixed model */
