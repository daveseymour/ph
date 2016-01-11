/*  unobserved components model                                              */
/*  simple explanations of model components can be found in Lavery (2004). An
    Animated Guide: Proc UCM (Unobserved Components Model). NESUG 17         */

options linesize=80;
ods graphics on;

data datetime;
    infile '~/ph/datetime/datetime.dat';
    input date_time animal day time dmi time tc rumenph reticph;
    format date_time datetime16.;
    logret = log(reticph);
run;

/*
proc timeseries data=datetime plot=series;
    by animal;
    id date_time interval=dtmin5;
    var logret;
run;
*/

/* dtmin5 is the notation for a 5-minute interval in datetime format */

proc ucm data=datetime;
    id date_time interval=dtmin5;
    by animal;
    estimate outest=params;

    model logret;
    level variance=0 noest;
    slope;
    *season length=864 type=trig;
    *autoreg;
    cycle;
run;

/* NOTES:

- No significant irregular error term
- No significant variation from level, but significant component
- No significant season error term
- No significant autoregressive term

*/

proc print data=params;
run;
