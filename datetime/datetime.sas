options linesize=80;

/* adding 300 to a datetime16 format variable increments in 5 minutes ahead */

data raw;
    infile '~/ph/ph.dat';
    input day animal silage dmi time rumenph reticph;
    tc = time + (day-1); /* convert all observations to continuous timecourse */
run;

data an52;
    animal = 52;
    dt_start = '23jan2014:05:58:16'dt;
    tc_start = 0;
    inc = (1/24/60*5);
    date_time = dt_start;
    tc = tc_start;

    do while (tc <= (15-inc));
        output;
        date_time = date_time + 300;
        tc = tc + inc;
    end;

    format date_time datetime16.;
    keep date_time animal;
run;

data an64;
    set an52;
    animal = 64;
run;

data an138;
    set an52;
    animal = 138;
run;

data an183;
    set an52;
    animal = 183;
run;

data dates;
    set an52 an64 an138 an183;

data total;
    merge raw dates;
    by animal;
run;

data total;
    set total;
    file 'datetime.dat';
    put dat_time animal day silage dmi time tc rumenph reticph;
run;

proc print data=total;
    where timepart(date_time)='05:58:16't;
run;

