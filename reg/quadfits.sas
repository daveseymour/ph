options linesize=80;
data read;
        infile 'ph.dat';
        input day animal silage dmi time rumenph reticph;

if animal ne 52 then delete;
if day ne 1 then delete;

time2=time**2;
time3=time**3;
time4=time**4;

proc reg data=read;
     by animal day;
     model reticph=time time2;
proc reg data=read;
     by animal day;
     model reticph=time time2 time3 ;
proc reg data=read;
     by animal day;
     model reticph=time time2 time3 time4;
run;


