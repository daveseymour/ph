/* Example from Cassel (2007) */
options linesize=80;

data temp1;
    x=1; y=45; output;
    do x = 2 to 29;
    y = 3*x + 6*rannor(1234);
    output;
    end;
    x=30; y=45; output;
run;

proc print;
run;

%let K=3;
%let rate=%sysevalf((&K-1)/&K);

/* generate the cross-validation sample */
proc surveyselect data=temp1 out=xv seed=495857
    samprate=&RATE outall rep=3;
run;

data xv;
    set xv;
    if selected then new_y=y;
    /* If observation is selected by PROC SURVEYSELECT, it is used as the training dataset and the original prediction is used */
    run;

proc print;
run;

/* get predicted values for the missing new_y in each replicate */
proc reg data=xv;
    model new_y=x;
    by replicate;
    output out=out1(where=(new_y=.)) p=yhat;
    /* Outputs a dataset of the testing set observations (i.e. new_y=.) with the predicted value for that replicate using the training set parameters (i.e. yhat) */
run;

/* summarize the results of the cross-validations */
data out2;
    set out1;
    d=y-yhat; /* New residual */
    absd=abs(d);
run;

proc print;
run;

proc summary data=out2;
    var d absd;
    output out=out3 std(d)=rmse mean(absd)=mae;
run;