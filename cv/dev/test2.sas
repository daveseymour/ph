options linesize=80;

data aormixed;
    infile '~/ph/resid/aormixed.dat';
    input animal day silage dmi time reticph retpred retresid rumenph rumpred rumresid lag1p lag3p lag2r lag4r lag7r lag9r;

proc summary data = aormixed;
    by animal day;
    output out= aniday;
run;

proc print data=aniday;