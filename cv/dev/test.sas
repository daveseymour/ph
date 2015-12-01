options linesize=80;
data xv;
    infile 'xv.dat';
    input replicate selected animal day silage dmi time reticph retpred retresid rumenph rumpred rumresid new_rumpred lag1p lag3p lag2r lag4r lag7r lag9r;
run;

/* Get predicted values for the missing new_rumpred in each replicate */
proc mixed data=xv lognote;
     by replicate;
    class animal day silage;
    model new_rumpred = reticph lag1p lag2r lag7r lag9r silage / solution outp=out1(where=(new_rumpred=.));
    random intercept retpred lag1p lag2r lag7r lag9r / type=arh(1) subject = animal*day;
run;

data out1;
    set out1;
    if selected ne 0 then delete;

/* Summarize the results of the cross-validations */

data out2;
    set out1;
    cv_rumpred = Pred;
    new_resid=rumpred - cv_rumpred;
    absr=abs(new_resid);
    drop Pred;
    file '10fcv.dat';
    put Replicate animal day silage dmi time reticph retpred retresid rumenph rumpred rumresid cv_rumpred new_resid absr;
run;

proc export
    data = out2
    file = '10fcv.xls'
    dbms = xls
    replace;
    sheet = 'Cross-Validation';

proc summary data=out2;
    var new_resid absr;
    output out=out3 std(new_resid)=rmse mean(absr)=mae;
run;

proc print data=out3;
