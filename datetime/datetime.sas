options linesize=80;

/* adding 300 to a datetime16 format variable increments in 5 minutes ahead */

data an52;
    start = '23jan2014:05:58:16'dt;
    end = '07feb2014:05:53:16'dt;
    date_time = start;
    do while (date_time <= end);
        output;
        date_time = date_time + 300;
    end;
    format date_time datetime16.;    
run;

proc print data=an52(keep=date_time);
run;
