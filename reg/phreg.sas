options linesize=80; /* Set SAS output to 80 character width */
data first;
    infile '~/ph/ph.dat';
    input date_time animal day silage dmi time tc rumenph reticph;
    label   dmi = 'DMI (kg)'
            rumenph = 'Ruminal pH'
            reticph = 'Reticular pH';

    *if animal ne 183 then delete;
    *if day ne 15 then delete;

    time2 = time**2;
    time3 = time**3;
    time4 = time**4;
    tc2 = tc**2;
    tc3 = tc**3;
    tc4 = tc**4;

proc sort data=first;
    by animal day;

proc reg data=first;
    title2 'Step 1: Generate 4th-Order Polynomial Regression of Reticular pH vs. Time';
    by animal day;
    Time: model reticph = time time2 time3 time4;
    TimeCourse: model reticph = tc tc2 tc3 tc4;
    output out=order4 p=retpred r=retresid;

data second;
    set order4;
    by animal day;
    lag1r = lag1(retresid); /* Lagged Residual Reticular pH */

proc pdlreg;
    by animal day;
    model rumenph = retpred(3,3) lag1r / method=ml nlag=1;
    output out=third p=rumpred r=rumresid;

data fourth;
    retain animal day silage dmi time rumenph rumpred rumresid reticph retpred retresid;
    set third;
    drop time2 time3 time4 lag1r;

proc print data=fourth;

proc export
    data=fourth
    file='phreg.xls'
    dbms=xls
    replace;
    sheet="NLAG1";
