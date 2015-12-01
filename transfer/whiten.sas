/* examination of transfer functions & 'prewhitening' */
/* adapted from Dickey (2007) */

options linesize=80;

data raw;
    infile '~/ph/ph.dat';
    input day animal silage dmi time rumenph reticph;
    tc = time + (day-1); /* convert all observations to continuous timecourse */
    logrum = log(rumenph);
    logret = log(reticph);
    rumresid = logrum-mean(logrum);
    retresid = logret-mean(logret);
run;

/* log transformation doesn't affect shape of distribution, just scale

proc sgplot;
    title2 'Rumen & Reticulum pH';
    scatter x=tc y=rumenph;
    scatter x=tc y=reticph;
run;

proc sgplot;
    title2 'Rumen & Reticulum pH (log)';
    scatter x=tc y=rumresid;
    scatter x=tc y=retresid;
run;
*/

/* test if AIC score improves with transformed variables */
/* log transformation improves AIC, no significant change in RSQ */

proc transreg data=raw noprint;
    title2 'Raw Variables';
    by animal;
    model identity(reticph) = pspline(tc / nknots=44);
    output out=norm predicted residual;
run;

proc reg data=norm outest=normcrit noprint;
    by animal;
    Raw: model reticph = tc_1 tc_2 tc_3 tc_4 tc_5 tc_6 tc_7 tc_8 tc_9 tc_10
        tc_11 tc_12 tc_13 tc_14 tc_15 tc_16 tc_17 tc_18 tc_19 tc_20 tc_21 tc_22
        tc_23 tc_24 tc_25 tc_26 tc_27 tc_28 tc_29 tc_30 tc_31 tc_32 tc_33 tc_34
        tc_35 tc_36 tc_37 tc_38 tc_39 tc_40 tc_41 tc_42 tc_43 tc_44 tc_45 tc_46
        tc_47 / rsquare adjrsq aic;

proc transreg data=raw noprint;
    title2 'Log Transformed Variables';
    by animal;
    model identity(logret) = pspline(tc / nknots=44);
    output out=log predicted residual;
run;

proc reg data=log outest=logcrit noprint;
    by animal;
    Log: model logret = tc_1 tc_2 tc_3 tc_4 tc_5 tc_6 tc_7 tc_8 tc_9 tc_10
        tc_11 tc_12 tc_13 tc_14 tc_15 tc_16 tc_17 tc_18 tc_19 tc_20 tc_21 tc_22
        tc_23 tc_24 tc_25 tc_26 tc_27 tc_28 tc_29 tc_30 tc_31 tc_32 tc_33 tc_34
        tc_35 tc_36 tc_37 tc_38 tc_39 tc_40 tc_41 tc_42 tc_43 tc_44 tc_45 tc_46
        tc_47 / rsquare adjrsq aic;
run;

data normcrit;
    set normcrit;
    keep Obs animal _MODEL_ _RMSE_ _RSQ_ _ADJRSQ_ _AIC_;

data logcrit;
    set logcrit;
    keep Obs animal _MODEL_ _RMSE_ _RSQ_ _ADJRSQ_ _AIC_;

proc print data=normcrit;
    title2 'Raw Variables';

proc print data=logcrit;
    title2 'Log Transformed';
