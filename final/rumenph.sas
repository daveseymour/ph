options linesize=80;

title 'Predicting the timecourse of ruminal pH from continuous reticular pH measurements';
/*
    D.J. Seymour*, K.M. Wood†, J.P. Cant* and G.B. Penner†
    * Department of Animal Biosciences, University of Guelph, Guelph, ON, N1G
        2W1
    † Department of Animal & Poultry Science, University of Saskatchewan,
        Saskatoon, SK, S7N 5A8

    note on nomenclature:
        - predicted values are prefixed with P
        - residuals are prefixed with R
        - output from TRANSREG has T suffix
        - output from MIXED has M suffix
        - output from UCM have U suffix
        - output from cross-validation is prefixed with xv_
        - lag variables are named in the style 'lag1p/r' to denote 1 lag of the
          predicted or residual value of reticph
*/

data ph;
    infile '~/ph/ph.dat';
    input date_time animal day silage dmi time tc rumenph reticph;
    format date_time datetime16.;

/*  generate predictions of reticph (PreticphT) */

proc transreg data=ph noprint;
    title2 'Prediction of Reticular pH Using Smoothing Spline';
    by animal;
    model identity(reticph) = pspline(tc / nknots=44);
    output out=transreg predicted residual;
run;

/*  generate lagged variables & merge TRANSREG output with original data*/

data transph;
    merge transreg ph;
    by animal tc;
    lag1p = lag1(Preticph);
    lag3p = lag3(Preticph);
    lag2r = lag2(Rreticph);
    lag4r = lag4(Rreticph);
    lag7r = lag7(Rreticph);
    lag9r = lag9(Rreticph);
    PreticphT = Preticph;
    RreticphT = Rreticph;
    keep date_time animal day silage dmi time tc rumenph reticph PreticphT
        RreticphT lag1p lag3p lag2r lag4r lag7r lag9r;
run;

/*  model rumen ph based on reticular ph predictions and residuals */

proc mixed data=transph covtest noitprint ic;
    title2 'Prediction of Rumen pH Using Predicted Reticular pH';
    class animal day silage;
    model rumenph = reticph lag1p lag2r lag7r lag9r silage / solution
        outp=mixed;
    random intercept PreticphT lag1p lag2r lag7r lag9r / type=un
        subject=animal*day;
run;

data mixed;
    set mixed;
    PrumenphM = Pred;
    RrumenphM = Resid;
    keep date_time animal day silage dmi time tc rumenph PrumenphM RrumenphM
        reticph PreticphT RreticphT lag1p lag3p lag2r lag4r lag7r lag9r;
    file 'mixed.dat';
    put date_time best16. animal day silage dmi time tc rumenph PrumenphM
        RrumenphM reticph PreticphT RreticphT lag1p lag3p lag2r lag4r lag7r
        lag9r;

/* alternate method: prediction from reticph using PROC UCM */

data ucm_in;
    set ph;
    if reticph = . then delete;
    if animal = 138 and date_time > '01feb14:15:33:16'dt then delete;
run;

proc ucm data = ucm_in;
    title2 'UCM with Cyclical Component';
    id date_time interval=dtmin5;
    by animal;

    model rumenph = reticph;
    level variance=0 noest;
    cycle;
    forecast print=none outfor=ucm_out;
run;

data ucm_out;
    set ucm_out;
    PrumenphU = FORECAST;
    RrumenphU = RESIDUAL;
    keep date_time animal rumenph PrumenphU RrumenphU reticph;
    file 'ucm.dat';
    put date_time best16. animal rumenph PrumenphU RrumenphU reticph;
run;

/* merge all predictions into total dataset */

proc sort data = mixed;
    by animal date_time;
run;

proc sort data = ucm_out;
    by animal date_time;
run;

data total;
    merge mixed ucm_out;
    by animal date_time;
    keep date_time animal day silage dmi time tc rumenph PrumenphM RrumenphM
        PrumenphU RrumenphU reticph PreticphT RreticphT lag1p lag3p lag2r lag4r
        lag7r lag9r;
    file 'total.dat';
    put date_time best16. animal day silage dmi time tc rumenph PrumenphM
        RrumenphM PrumenphU RrumenphU reticph PreticphT RreticphT lag1p lag3p
        lag2r lag4r lag7r lag9r;
run;

/*  perform 10-fold cross validation */
/*  adapted from Cassel (2007) */
/*  generate list of animal-day subsets */

proc summary data = total;
    title2 'Generation of Animal-Day Subsets';
    by animal day;
    output out= aniday;
run;

data aniday;
    set aniday;
    drop _TYPE_ _FREQ_;
    if animal = 52 and day > 12 then delete;
run;

/*  generate cross-validation datasets */
/*  always manually select seed for repeatability */

%let K=10;
%let rate=%sysevalf((&K-1)/&K);

proc surveyselect data=aniday out=train seed=495857 samprate=&RATE outall
    rep=10;
    title2 'Selection of Training & Testing Datasets';
run;

proc sort data = train;
    by animal day;

data train1 train2 train3 train4 train5 train6 train7 train8 train9 train10;
    set train;
    if replicate = 1 then output train1;
    if replicate = 2 then output train2;
    if replicate = 3 then output train3;
    if replicate = 4 then output train4;
    if replicate = 5 then output train5;
    if replicate = 6 then output train6;
    if replicate = 7 then output train7;
    if replicate = 8 then output train8;
    if replicate = 9 then output train9;
    if replicate = 10 then output train10;
run;

/*
    merge selection results to data. errors occur when merging multiple
    replicates, need to make form individual datasets for each replicate
    and merge at end
*/

data xv1;
    merge train1 total;
    by animal day;
run;

data xv2;
    merge train2 total;
    by animal day;
run;

data xv3;
    merge train3 total;
    by animal day;
run;

data xv4;
    merge train4 total;
    by animal day;
run;

data xv5;
    merge train5 total;
    by animal day;
run;

data xv6;
    merge train6 total;
    by animal day;
run;

data xv7;
    merge train7 total;
    by animal day;
run;

data xv8;
    merge train8 total;
    by animal day;
run;

data xv9;
    merge train9 total;
    by animal day;
run;

data xv10;
    merge train10 total;
    by animal day;
run;

data xv_in;
    set xv1 xv2 xv3 xv4 xv5 xv6 xv7 xv8 xv9 xv10;
    if selected then new_PrumenphM = PrumenphM;
    if selected then new_PrumenphU = PrumenphU;
    if replicate = . then delete;
    file 'xv_in.dat';
    put replicate selected date_time best16. animal day silage dmi time tc rumenph
        PrumenphM RrumenphM PrumenphU RrumenphU new_PrumenphM new_PrumenphU
        reticph PreticphT RreticphT;
run;

proc sort data=xv_in;
    by replicate animal date_time;
run;

/*  get predicted values for new_PrumenphM in each replicate */
/* used mivque0 because of 'too many likelihoods' error */

proc mixed data=xv_in method=mivque0 lognote;
    title2 '10-Fold Cross Validation - PROC MIXED';
    by replicate;
    class animal day silage;
    model new_PrumenphM = reticph lag1p lag2r lag7r lag9r silage / solution
        outp=xv_Mixed(where=(new_PrumenphM=.));
    random intercept PreticphT lag1p lag2r lag7r lag9r / type=un
        subject=animal*day;
run;

/* get predicted values for new_PrumenphU in each replicate */


proc ucm data=xv_in;
    title2 '10-Fold Cross Validation - PROC UCM';
    id date_time interval=dtmin5;
    by replicate animal;

    model new_PrumenphU = reticph;
    level variance=0 noest;
    cycle;
    forecast print=none outfor=xv_UCM(where=(new_PrumenphU=.));
run;

/*  summarize results of cross validation */

proc sort data = xv_Mixed;
    by replicate animal date_time;
run;

proc sort data = xv_UCM;
    by replicate animal date_time;
run;

data xv_out;
    merge xv_Mixed xv_UCM;
    by replicate animal date_time;
    if selected ne 0 then delete;
    xv_PrumenphM = Pred;
    xv_RrumenphM = rumenph - xv_PrumenphM;
    absrM = abs(xv_RrumenphM);
    xv_PrumenphU = FORECAST;
    xv_RrumenphU = rumenph - xv_PrumenphU;
    absrU = abs(xv_RrumenphU);
    keep replicate date_time animal day silage dmi rumenph PrumenphM RrumenphM
        xv_PrumenphM xv_RrumenphM absrM PrumenphU RrumenphU xv_PrumenphU
        xv_RrumenphU absrU reticph PreticphT RreticphT;
    file 'xv_pred.dat';
    put replicate date_time best16. animal day silage dmi rumenph PrumenphM
        RrumenphM xv_PrumenphM xv_RrumenphM absrM PrumenphU RrumenphU
        xv_PrumenphU xv_RrumenphU absrU reticph PreticphT RreticphT;
run;

proc summary data=xv_out;
    title2 '10-Fold Cross Validation Summary';
    title3 'MAE: Mean Absolute Error';
    var xv_RrumenphM xv_RrumenphU absrM absrU;
    output out=summary std(xv_RrumenphM)=RMSE_Mixed mean(absrM)=MAE_Mixed
        min(xv_RrumenphM)=min_M max(xv_RrumenphM)=max_M
        std(xv_RrumenphU)=RMSE_UCM mean(absrU)=MAE_UCM min(xv_RrumenphU)=min_U
        max(xv_RrumenphU)=max_U;
run;

proc print data=summary;
run;
