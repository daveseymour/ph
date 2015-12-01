options linesize=80;
title 'Analysis of Residuals - PROC MIXED';

data raw;
    infile '~/ph/ph.dat';
    input day animal silage dmi time rumenph reticph;

    *if animal ne 52 then delete;
    *if day ne 1 then delete;

    time2 = time**2;
    time3 = time**3;
    time4 = time**4;

proc reg data=raw noprint;
    title2 'Reticph Prediction';
    by animal day;
    model reticph = time time2 time3 time4;
    output out=quadfit p=retpred r=retresid;
run;

data quadfit;
    set quadfit;
    lag1p = lag1(retpred);
    lag3p = lag3(retpred);
    lag2r = lag2(retresid);
    lag4r = lag4(retresid);
    lag7r = lag7(retresid);
    lag9r = lag9(retresid);
    drop time2 time3 time4;

proc mixed covtest lognote;
    class animal day silage;
    model rumenph = reticph lag1p lag2r lag7r lag9r silage / solution outp=preds;
    random intercept retpred lag1p lag2r lag7r lag9r / type=un subject=animal*day;

    /* AICC no silage: -18577.4 */
    /* AICC silage covariate: -18591.3 */
    /* Best fit - AICC silage class variable: -18592.2 */

data aormixed;
     set preds;
     rumpred = Pred;
     rumresid = Resid;
     drop Pred DF Alpha Lower Upper Resid;
     file 'aormixed.dat';
     put animal day silage dmi time reticph retpred retresid rumenph rumpred rumresid lag1p lag3p lag2r lag4r lag7r lag9r;
run;