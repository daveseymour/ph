/* UCM to describe forecast rumen ph directly from reticular ph timecourse */

options linesize=80;
ods graphics on;

data ph;
    infile '~/ph/ph.dat';
    input date_time animal day silage dmi time tc rumenph reticph;
    format date_time datetime16.;
    logret = log(reticph);
    logrum = log(rumenph);
    if reticph = . then delete;
    if animal ne 52 then delete;
    /* program will fail if any missing observations are included */
run;

proc timeseries data=ph
    (where=('31jan2014:06:00:00'dt < date_time < '06feb2014:06:00:00'dt))
    plot = (series corr decomp);
    id date_time interval=dtmin5;
    var rumenph reticph;
run;


proc ucm data = ph;
    id date_time interval=dtmin5;
    by animal;

    model rumenph = reticph;
    * logret AICC -23117 AdjRsq 0.93882
    * lag3r AICC -20857 AdjRsq 0.88249

    level variance=0 noest;
    cycle;
    forecast back=144 lead=144 print=forecasts;
run;
