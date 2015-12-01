title 'pH Prediction - AUTOREG';

/* Set output to 80 character width */
options linesize=80;

/* Data Translation */
data read;
    infile 'ph.dat';
    input day animal silage dmi time rumenph reticph;

oldreticph=reticph;
oldrumenph=rumenph;

/* Delete data except for first animal, first day for testing purposes */
if animal ne 52 then delete;
if day ne 1 then delete;

lag1=lag1(reticph);
lag2=lag2(reticph);
lag3=lag3(reticph);
lag4=lag4(reticph);
lag5=lag5(reticph);
lag6=lag6(reticph);
lag7=lag7(reticph);
lag8=lag8(reticph);
lag9=lag9(reticph);
lag10=lag10(reticph);
lag11=lag11(reticph);
lag12=lag12(reticph);

/* regression of rumen ph on past 4 reticph values, with correction for
autocorrelation b/w resids */

proc autoreg data=read;
     by animal day;
     model rumenph=reticph lag1 lag2 lag3 lag4 lag5 lag6 lag7 lag8 lag9 lag10
        lag11 lag12 / nlag=10 method=ml backstep;

/* nlag=1 specifies autoregressive correction of reticph inputs from previous 1
reticph */

output out=new p=pred rm=residph transform=rumenph transform=reticph;

proc export
	data=new
	outfile="phregdev.xls"
	dbms=xls
	replace;
	sheet="autoreg";