/* Adapted from Cassel (2007) */
options linesize=80;

data aormixed;
    infile '~/ph/resid/aormixed.dat';
    input animal day silage dmi time reticph retpred retresid rumenph rumpred rumresid lag1p lag3p lag2r lag4r lag7r lag9r;
    if animal = 52 and day > 12 then delete;

/* Instead picking from full dataset, can randomly pick from dataset of only animal-day combinations */

proc summary data = aormixed;
    by animal day;
    output out= aniday;
run;

data aniday;
    set aniday;
    drop _TYPE_ _FREQ_;
    if animal = 52 and day > 12 then delete;
run;

%let K=10;
%let rate=%sysevalf((&K-1)/&K);

/* Generate the cross-validation sample */
proc surveyselect data=aniday out=train seed=495857
    samprate=&RATE outall rep=10;
    /* Always manually select seed for repeatability */
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

/* Merge selection criteria to data */
/* When doing more than one replicate, datasets dont match up properly. Need to make separate dataset per replicate and merge to data separately */

data xv1;
    merge train1 aormixed;
    by animal day;
run;

data xv2;
    merge train2 aormixed;
    by animal day;
run;

data xv3;
    merge train3 aormixed;
    by animal day;
run;

data xv4;
    merge train4 aormixed;
    by animal day;
run;

data xv5;
    merge train5 aormixed;
    by animal day;
run;

data xv6;
    merge train6 aormixed;
    by animal day;
run;

data xv7;
    merge train7 aormixed;
    by animal day;
run;

data xv8;
    merge train8 aormixed;
    by animal day;
run;

data xv9;
    merge train9 aormixed;
    by animal day;
run;

data xv10;
    merge train10 aormixed;
    by animal day;
run;

data xv;
    set xv1 xv2 xv3 xv4 xv5 xv6 xv7 xv8 xv9 xv10;
    if selected then new_rumpred = rumpred;
    file 'xv.dat';
    put replicate selected animal day silage dmi time reticph retpred retresid rumenph rumpred rumresid new_rumpred;
run;



/* Get predicted values for the missing new_rumpred in each replicate */
proc mixed data=xv method=mivque0 lognote;
    by replicate;
    class animal day silage;
    model new_rumpred = reticph lag1p lag2r lag7r lag9r silage / solution outp=out1(where=(new_rumpred=.));
    random intercept retpred lag1p lag2r lag7r lag9r / type=un subject=animal*day;
run;

data out1;
    set out1;
    if selected ne 0 then delete;

/* Summarize the results of the cross-validations */
data out2;
    set out1;
    cv_rumpred = Pred;
    new_resid=rumenph - cv_rumpred;
    absr=abs(new_resid);
    drop Pred;
    file '10fcv.dat';
    put replicate animal day silage dmi time reticph retpred retresid rumenph rumpred rumresid cv_rumpred new_resid absr;
run;

proc export
    data = out2
    file = '10fcv.csv'
    dbms = csv
    replace;

proc summary data=out2;
    var new_resid absr;
    output out=out3 std(new_resid)=RMSE mean(absr)=MAE;
run;

proc print data=out3;
