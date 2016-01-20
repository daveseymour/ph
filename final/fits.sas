/* output goodness of fit stats for each procedure used */
options linesize=80 pagesize=53;

title 'Rumen pH Model Fit Statistics';

data ph;
    infile '~/ph/ph.dat';
    input date_time animal day silage dmi time tc rumenph reticph;
    time2 = time**2;
    time3 = time**3;
    time4 = time**4;
    tc2 = tc**2;
    tc3 = tc**3;
    tc4 = tc**4;

/* prediction of reticular ph from time - REG vs. TRANSREG*/
/* can't get AIC value for pspline in TRANSREG, need to run output through
    REG */

proc reg data=ph outest=reg_fits rsquare adjrsq aic noprint;
    title2 'Prediction of reticph - REG';
    by animal day;
    TimeCourse: model reticph = tc tc2 tc3 tc4;
    output out=reg_out p=PreticphR r=RreticphR;
run;

/* format reg output */
data reg_out;
    set reg_out;
    lag1pR = lag1(PreticphR);
    lag3pR = lag3(PreticphR);
    lag1rR = lag1(RreticphR);
    lag2rR = lag2(RreticphR);
    lag4rR = lag4(RreticphR);
    lag7rR = lag7(RreticphR);
    lag9rR = lag9(RreticphR);
    keep date_time animal day silage dmi time tc rumenph reticph PreticphR
        RreticphR lag1pR lag3pR lag1rR lag2rR lag4rR lag7rR lag9rR;
run;

proc sort data=reg_out;
    by animal tc;
run;

/* format reg stats */
data reg_fits;
    set reg_fits;
    keep animal day _MODEL_ _RMSE_ _RSQ_ _ADJRSQ_ _AIC_;
run;

proc transreg data=ph noprint;
    title2 'Prediction of reticph - TRANSREG';
    by animal;
    model identity(reticph) = pspline(tc / nknots=44);
    output out=transreg_out coefficients predicted residual;
run;

/* calculate transreg fit stats */
proc reg data=transreg_out outest=transreg_fits rsquare adjrsq aic noprint;
    title2 'Calculation of TRANSREG fit statistics using REG';
    by animal;
    Spline: model reticph = tc_1 tc_2 tc_3 tc_4 tc_5 tc_6 tc_7 tc_8 tc_9 tc_10
        tc_11 tc_12 tc_13 tc_14 tc_15 tc_16 tc_17 tc_18 tc_19 tc_20 tc_21 tc_22
        tc_23 tc_24 tc_25 tc_26 tc_27 tc_28 tc_29 tc_30 tc_31 tc_32 tc_33 tc_34
        tc_35 tc_36 tc_37 tc_38 tc_39 tc_40 tc_41 tc_42 tc_43 tc_44 tc_45 tc_46
        tc_47;
run;

/* format trasreg output */
data transreg_out;
    set transreg_out;
    PreticphT = Preticph;
    RreticphT = Rreticph;
    lag1pT = lag1(Preticph);
    lag3pT = lag3(Preticph);
    lag1rT = lag1(Rreticph);
    lag2rT = lag2(Rreticph);
    lag4rT = lag4(Rreticph);
    lag7rT = lag7(Rreticph);
    lag9rT = lag9(Rreticph);
    keep animal tc reticph PreticphT RreticphT lag1pT lag3pT lag1rT lag2rT
    lag4rT lag7rT lag9rT;
run;

proc sort data=transreg_out;
    by animal tc;

/* format transreg fit stats */
data transreg_fits;
    set transreg_fits;
    keep animal _MODEL_ _RMSE_ _RSQ_ _ADJRSQ_ _AIC_;
run;

/* merge reticular ph predictions */
data regtransreg;
    merge reg_out transreg_out;
    by animal tc;
    if date_time = . then delete;
run;

proc sort data=regtransreg;
    by animal date_time;

/* prediction of rumen ph from PreticphR/T - PDLREG vs. MIXED */

proc pdlreg data=regtransreg method=ml;
    title2 'Predicting rumenph - PDLREG Model - REG Inputs';
    by animal;
    REG: model rumenph = PreticphR(3,3) lag1rR silage;
    output out=pdlregR_out p=PrumenphRP r=RrumenphRP;
    ods output FitSummary=pdlregR_fits;
run;

proc pdlreg data=regtransreg method=ml;
    title2 'Predicting rumenph - PDLREG Model - TRANSREG Inputs';
    by animal;
    TRANSREG: model rumenph = PreticphT(3,3) lag1rT silage;
    output out=pdlregT_out p=PrumenphTP r=RrumenphTP;
    ods output FitSummary=pdlregT_fits;
run;

/* format pdelreg output */
data pdlregR_out;
    set pdlregR_out;
    keep date_time animal day silage dmi time tc rumenph PrumenphRP RrumenphRP
        reticph PreticphR RreticphR;
run;

proc sort data=pdlregR_out;
    by animal date_time;
run;

data pdlregT_out;
    set pdlregT_out;
    keep date_time animal day silage dmi time tc rumenph PrumenphTP RrumenphTP
        reticph PreticphT RreticphT;
run;

proc sort data=pdlregT_out;
    by animal date_time;

proc print data=pdlregT_out(obs=10);
run;

proc mixed data=regtransreg covtest noitprint ic;
    title2 'Predicting rumenph - MIXED Model - REG Inputs';
    class animal day silage;
    model rumenph = reticph lag1pR lag2rR lag7rR lag9rR silage / solution
        outp=mixedR_out;
    random intercept PreticphR lag1pR lag2rR lag7rR lag9rR / type=un
        subject=animal*day;
    ods output FitStatistics=mixedR_fits;
run;

proc mixed data=regtransreg covtest noitprint ic;
    title2 'Predicting rumenph - MIXED Model - TRANSREG Inputs';
    class animal day silage;
    model rumenph = reticph lag1pT lag2rT lag7rT lag9rT silage / solution
        outp=mixedT_out;
    random intercept PreticphT lag1pT lag2rT lag7rT lag9rT / type=un
        subject=animal*day;
    ods output FitStatistics=mixedT_fits;
run;

/* format mixed output */

data mixedR_out;
    set mixedR_out;
    PrumenphRM = Pred;
    RrumenphRM = Resid;
    keep date_time animal day silage dmi time tc rumenph PrumenphRM RrumenphRM
        reticph PreticphR RreticphR;
run;

proc sort data=mixedR_out;
    by animal date_time;
run;

data mixedT_out;
    set mixedT_out;
    PrumenphTM = Pred;
    RrumenphTM = Resid;
    keep date_time animal day silage dmi time tc rumenph PrumenphTM RrumenphTM
        reticph PreticphT RreticphT;
run;

proc sort data=mixedT_out;
    by animal date_time;

/* prediction of rumenph from reticph - UCM */

data ucm_in;
    set ph;
    forat date_time datetime16.;
    if reticph = . then delete;
    if animal = 138 and date_time >= '01feb14:15:33:16'dt then delete;
run;

proc ucm data=ucm_in;
    title2 'Predicting rumenph - UCM';
    id date_time interval=dtmin5;
    by animal;

    model rumenph = reticph;
    level variance=0 noest;
    cycle;
    forecast print=none outfor=ucm_out;
    ods output FitStatistics=ucm_fits_residuals FitSummary=ucm_fits_likelihood;
run;

/* format ucm output */

data ucm_out;
    set ucm_out;
    format date_time best.;
    PrumenphU = FORECAST;
    RrumenphU = RESIDUAL;
    keep date_time animal rumenph PrumenphU RrumenphU reticph;
run;

proc sort data=ucm_out;
    by animal date_time;

data all_fits;
    merge regtransreg pdlregR_out pdlregT_out mixedR_out mixedT_out ucm_out;
    by animal date_time;
    keep date_time animal day silage dmi time tc rumenph PrumenphRP RrumenphRP
        PrumenphTP RrumenphTP PrumenphRM RrumenphRM PrumenphTM RrumenphTM
        PrumenphU RrumenphU reticph PreticphR RreticphR PreticphT RreticphT;
    file 'all_fits.dat';
    put date_time animal day silage dmi time tc rumenph PrumenphRP
        RrumenphRP PrumenphTP RrumenphTP PrumenphRM RrumenphRM PrumenphTM
        RrumenphTM PrumenphU RrumenphU reticph PreticphR RreticphR PreticphT
        RreticphT;
run;

proc print data=reg_fits;
    title2 'PROC REG Fits';

proc print data=transreg_fits;
    title2 'PROC TRANSREG Fits';

proc print data=pdlregR_fits;
    title2 'PROC PDLREG - REG Inputs Fits';

proc print data=pdlregT_fits;
    title2 'PROC PDLREG - TRANSREG Inputs Fits';

proc print data=mixedR_fits;
    title2 'PROC MIXED - REG Inputs Fits';

proc print data=mixedT_fits;
    title2 'PROC MIXED - TRANSREG Inputs Fits';

proc print data=ucm_fits_residuals;
    title2 'PROC UCM - Residual Fits';

proc print data=ucm_fits_likelihood;
    title2 'PROC UCM - Likelihood Fits';
run;
