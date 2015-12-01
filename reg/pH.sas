title 'Ruminal vs. Reticular pH';
options linesize=80;

data first;
	infile 'ph.dat';
    input day animal silage dmi time rumenph reticph;

	time2=time**2;
	time3=time**3;
	time4=time**4;

proc sort;
	by animal day time;

/** Calculate regression coefficients with AIC and R square & output to data file **/
/** SAS encounters errors for animal 52 days 13,14,15 due to no data **/
proc reg outest=coeff aic rsquare;
	by animal day;
	Order2 : model reticph=time time2;
	Order3 : model reticph=time time2 time3;
	Order4 : model reticph=time time2 time3 time4;
	output out=third p=retpred r=retresid;
run;

data coeff;
    set coeff;
    drop _TYPE_ _DEPVAR_ _IN_ _P_ _EDF_;

/** Export datasets to Excel file **/
proc export
	data=first
	outfile="procreg.xls"
	dbms=xls
	replace;
	sheet="data";

proc export
	data=coeff
	outfile="procreg.xls"
	dbms=xls
	replace;
	sheet="coeff";

proc export
	data=third
	outfile="procreg.xls"
	dbms=xls
	replace;
	sheet="reg";
run;
