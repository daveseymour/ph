title 'Rumen pH Model - Analysis of Residuals';
options linesize=80;

data first;
    infile 'resid33.dat';
    input animal day silage dmi time reticph retpred retresid rumenph rumpred rumresid;

proc glm;
    class silage dmi time retpred;
    model rumresid = silage dmi time silage*time / ss3;
run;