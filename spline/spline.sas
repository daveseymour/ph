title 'Reticular pH Prediction - 4th Order vs. Spline';

options linesize = 80;

data aormixed;
    infile '~/ph/resid/aormixed.dat';
    input animal day silage dmi time reticph retpred retresid rumenph rumpred
        rumresid lag1p lag3p lag2r lag4r lag7r lag9r;
    if animal = 52 and day > 12 then delete;
    tc = time + (day-1);
    time2 = time**2;
    time3 = time**3;
    time4 = time**4;
    tc2 = tc**2;
    tc3 = tc**3;
    tc4 = tc**4;
run;

proc reg noprint outest=quadfits;
    title2 '4th Order Polynomial';
    by animal;
    Day: model reticph = time time2 time3 time4 / rsquare adjrsq aic;
    TimeCourse: model reticph = tc tc2 tc3 tc4 / rsquare adjrsq aic;
run;

proc transreg data=aormixed noprint;
    title2 'Cubic Spline w/ 44 Knots';
    by animal;
    model identity(reticph) = pspline(tc / nknots=44);
    output out=spline coefficients;
run;

/*proc print data=spline;
    where _TYPE_ eq 'M COEFFI';
run;
*/
proc reg data=spline outest=splinefits noprint;
    by animal;
    Spline: model reticph = tc_1 tc_2 tc_3 tc_4 tc_5 tc_6 tc_7 tc_8 tc_9 tc_10
        tc_11 tc_12 tc_13 tc_14 tc_15 tc_16 tc_17 tc_18 tc_19 tc_20 tc_21 tc_22
        tc_23 tc_24 tc_25 tc_26 tc_27 tc_28 tc_29 tc_30 tc_31 tc_32 tc_33 tc_34
        tc_35 tc_36 tc_37 tc_38 tc_39 tc_40 tc_41 tc_42 tc_43 tc_44 tc_45 tc_46
        tc_47 / rsquare adjrsq aic;
    output out=spline_reg predicted=pred;
run;

data quadfits;
    set quadfits;
    keep Obs animal _MODEL_ _RMSE_ _RSQ_ _ADJRSQ_ _AIC_;

data splinefits;
    set splinefits;
    keep Obs animal _MODEL_ _RMSE_ _RSQ_ _ADJRSQ_ _AIC_;

proc print data=quadfits;
    title2 '4th-Order Polynomial Fits';
    where _MODEL_ eq 'TimeCourse';
proc print data=splinefits;
    title2 'Cubic Spline with 44 Knots Fits';
