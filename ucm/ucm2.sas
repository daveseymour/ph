/* UCM to describe forecast rumen ph directly from reticular ph timecourse */

options linesize=80;
ods graphics on;
title 'Rumen pH Unobserved Components Model';

data ph;
    infile '~/ph/ph.dat';
    input date_time animal day silage dmi time tc rumenph reticph;
    format date_time datetime16.;
    logret = log(reticph);
    logrum = log(rumenph);
    if reticph = . then delete;
    /* program will fail if any missing dependant variable
    observations are included */
run;

proc ucm data = ph;
    title2 'UCM with Cyclical Component';
    id date_time interval=dtmin5;
    by animal;

    model rumenph = reticph;
    /*  logret AICC -23117 AdjRsq 0.93882
        lag3r AICC -20857 AdjRsq 0.88249 */

    level variance=0 noest;
    cycle;

    estimate plot=panel;
    forecast print=none outfor=forecast;
run;

/* Model testing:

level variance=0 noest, cycle: AICC -9888 AdjRSQ 0.94181
level variance=0 noest, autoreg: AICC -9890 AdjRSQ 0.94184

*/
