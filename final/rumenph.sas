options linesize=80;

title 'Predicting the timecourse of ruminal pH from continuous reticular pH measurements';
/*
    D.J. Seymour*, K.M. Wood†, J.P. Cant* and G.B. Penner†
    * Department of Animal Biosciences, University of Guelph, Guelph, ON, N1G
        2W1
    † Department of Animal & Poultry Science, University of Saskatchewan,
        Saskatoon, SK, S7N 5A8
*/

data raw;
    infile '~/ph/ph.dat';
    input day animal silage dmi time rumenph reticph;
    tc = time + (day-1); /* convert all observations to continuous timecourse */
run;

/*  generate predictions of reticph (Preticph) */

proc transreg data=raw noprint;
    title2 'Prediction of Reticular pH Using Smoothing Spline';
    by animal;
    model identity(reticph) = pspline(tc / nknots=44);
    output out=transreg predicted residual;
run;

/*  generate lagged variables & merge TRANSREG output with original data*/
/*  note on nomenclature:
/*      - predicted values are prefixed with P
/*      - residuals are prefixed with R
/*      - lag variables are named in the style 'lag1p/r' to denote 1 lag of the
/*          predicted or residual value of reticph */

data merged;
    merge transreg raw;
    by animal tc;
    lag1p = lag1(Preticph);
    lag3p = lag3(Preticph);
    lag2r = lag2(Rreticph);
    lag4r = lag4(Rreticph);
    lag7r = lag7(Rreticph);
    lag9r = lag9(Rreticph);
    keep animal day silage dmi time tc reticph Preticph Rreticph rumenph lag1p
        lag3p lag2r lag4r lag7r lag9r;
run;

/*  model rumen ph based on reticular ph predictions and residuals */

proc mixed data=merged covtest noitprint ic;
    title2 'Prediction of Rumen pH Using Predicted Reticular pH';
    class animal day silage;
    model rumenph = reticph lag1p lag2r lag7r lag9r silage / solution
        outp=mixed;
    random intercept Preticph lag1p lag2r lag7r lag9r / type=un
        subject=animal*day;
run;

/*  prepare data for cross-validation of model */
/*  adapted from Cassel (2007) */

data mixed;
    set mixed;
    Prumenph = Pred;
    Rrumenph = Resid;
    drop Pred Resid Alpha DF Upper Lower;
    file 'mixed.dat';
    put animal day silage dmi time tc reticph Preticph Rreticph rumenph Prumenph
        Rrumenph lag1p lag3p lag2r lag4r lag7r lag9r;

/*  perform 10-fold cross validation */
/*  generate list of animal-day subsets */

proc summary data = mixed;
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
    merge train1 mixed;
    by animal day;
run;

data xv2;
    merge train2 mixed;
    by animal day;
run;

data xv3;
    merge train3 mixed;
    by animal day;
run;

data xv4;
    merge train4 mixed;
    by animal day;
run;

data xv5;
    merge train5 mixed;
    by animal day;
run;

data xv6;
    merge train6 mixed;
    by animal day;
run;

data xv7;
    merge train7 mixed;
    by animal day;
run;

data xv8;
    merge train8 mixed;
    by animal day;
run;

data xv9;
    merge train9 mixed;
    by animal day;
run;

data xv10;
    merge train10 mixed;
    by animal day;
run;

data xv;
    set xv1 xv2 xv3 xv4 xv5 xv6 xv7 xv8 xv9 xv10;
    if selected then new_Prumenph = Prumenph;
    if replicate = . then delete;
    file 'xv.dat';
    put replicate selected animal day silage dmi time tc reticph Preticph
        Rreticph rumenph Prumenph Rrumenph new_Prumenph;
run;

proc sort data=xv;
    by replicate animal day;
run;

/*  get predicted values for new_Prumenph in each replicate */

proc mixed data=xv method=mivque0;
    /* used mivque0 because of 'too many likelihoods' error */
    by replicate;
    class animal day silage;
    model new_Prumenph = reticph lag1p lag2r lag7r lag9r silage / solution
        outp=xv_pred(where=(new_Prumenph=.));
    random intercept Preticph lag1p lag2r lag7r lag9r / type=un
        subject=animal*day;
run;

/*  summarize results of cross validation */

data xv_pred;
    set xv_pred;
    if selected ne 0 then delete;
    xv_Prumenph = Pred;
    xv_Rrumenph = rumenph - xv_Prumenph;
    absr = abs(xv_Rrumenph);
    file 'xv_pred.dat';
    put replicate animal day silage dmi time tc reticph Preticph Rreticph
        rumenph Prumenph Rrumenph xv_Prumenph xv_Rrumenph absr;
run;

proc summary data=xv_pred;
    title2 '10-Fold Cross Validation Summary';
    title3 'MAE: Mean Absolute Error';
    var xv_Rrumenph absr;
    output out=summary std(xv_Rrumenph)=RMSE mean(absr)=MAE;
run;

proc print data=summary;
run;
