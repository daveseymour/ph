title 'Prediction of Ruminal pH Using Reticuluar pH';

options linesize=80; /* Set SAS output to 80 character width */
data first;
    infile '~/pH/ph.dat';
    input day animal silage dmi time rumenph reticph;
    label   dmi = 'DMI (kg)'
            rumenph = 'Ruminal pH'
            reticph = 'Reticular pH';

    if dmi ne 4 then delete;
    *time = time + (day - 1); /* Converts all days into continuous series */

    time2 = time**2;
    time3 = time**3;
    time4 = time**4;


proc reg data=first noprint;
    title2 'Step 1: Generate 4th-Order Polynomial Regression of Reticular pH vs. Time';
    by dmi;
    Order4: model reticph = time time2 time3 time4;
    output out=order4 p=pred r=resid;

data second;
    set order4;
    /* Lagged Predicted Reticular pH */
    lag1p = lag1(pred);
    lag2p = lag2(pred);
    lag3p = lag3(pred);
    lag4p = lag4(pred);
    lag5p = lag5(pred);
    lag6p = lag6(pred);
    lag7p = lag7(pred);
    lag8p = lag8(pred);
    lag9p = lag9(pred);
    lag10p = lag10(pred);

    /* Lagged Residual Reticular pH */
    lag1r = lag1(resid);
    lag2r = lag2(resid);
    lag3r = lag3(resid);
    lag4r = lag4(resid);
    lag5r = lag5(resid);
    lag6r = lag6(resid);
    lag7r = lag7(resid);
    lag8r = lag8(resid);
    lag9r = lag9(resid);
    lag10r = lag10(resid);


proc pdlreg data=second noprint;
    by dmi;
    title2 'Step 2: Determine Optimal Degree for Distribution';
    model rumenph = pred(12,10,1) lag1r;


/* Enable proc below after determining degree */

proc pdlreg data=second method=ml noprint;
    title2 'Step 3: Primary Lag Number Determination';
    X: model rumenph = pred(10,1) lag1r;
    XX: model rumenph = pred(20,1) lag1r;
    XXX: model rumenph = pred(30,1) lag1r;
    XL: model rumenph = pred(40,1) lag1r;
    L: model rumenph = pred(50,1) lag1r;
    LX: model rumenph = pred(60,1) lag1r;
    LXX: model rumenph = pred(70,1) lag1r;
    LXXX: model rumenph = pred(80,1) lag1r;
    XC: model rumenph = pred(90,1) lag1r;
    C: model rumenph = pred(100,1) lag1r;
    CX: model rumenph = pred(110,1) lag1r;
    CXX: model rumenph = pred(120,1) lag1r;
    CXXX: model rumenph = pred(130,1) lag1r;
    CXL: model rumenph = pred(140,1) lag1r;
    CL: model rumenph = pred(150,1) lag1r;
    CLX: model rumenph = pred(160,1) lag1r;
    CLXX: model rumenph = pred(170,1) lag1r;
    CLXXX: model rumenph = pred(180,1) lag1r;
    CXC: model rumenph = pred(190,1) lag1r;
    CC: model rumenph = pred(200,1) lag1r;

/* Enable proc below after determining suitable starting lag */
/* NOTE: If the degree of the distribution is higher than the lag number, SAS
    will automatically lower the degree to match */

proc pdlreg data=second method=ml;
    title2 'Step 4: Lag Number Optimization';
    N10_Lags: model rumenph = pred(10,1) lag1r;
    N9_Lags: model rumenph = pred(1,1) lag1r;
    N8_Lags: model rumenph = pred(2,1) lag1r;
    N7_Lags: model rumenph = pred(3,1) lag1r;
    N6_Lags: model rumenph = pred(4,1) lag1r;
    N5_Lags: model rumenph = pred(5,1) lag1r;
    N4_Lags: model rumenph = pred(6,1) lag1r;
    N3_Lags: model rumenph = pred(7,1) lag1r;
    N2_Lags: model rumenph = pred(8,1) lag1r;
    N1_Lags: model rumenph = pred(9,1) lag1r;
    O_Lags: model rumenph = pred(10,1) lag1r;
    P1_Lags: model rumenph = pred(11,1) lag1r;
    P2_Lags: model rumenph = pred(12,1) lag1r;
    P3_Lags: model rumenph = pred(13,1) lag1r;
    P4_Lags: model rumenph = pred(14,1) lag1r;
    P5_Lags: model rumenph = pred(15,1) lag1r;
    P6_Lags: model rumenph = pred(16,1) lag1r;
    P7_Lags: model rumenph = pred(17,1) lag1r;
    P8_Lags: model rumenph = pred(18,1) lag1r;
    P9_Lags: model rumenph = pred(19,1) lag1r;
    P10_Lags: model rumenph = pred(20,1) lag1r;

run;