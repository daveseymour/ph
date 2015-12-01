options linesize=80;

data first;
    infile 'resid33.dat';
    input animal day silage dmi time reticph retpred retresid rumenph rumpred rumresid;
    lag1r = lag1(retresid);

proc mixed covtest method=ml;
    by animal day;
    class animal retpred lag1r silage;
    model rumenph = retpred lag1r silage / ddfm=kr;
    random animal;
    repeated / subject=animal;
    lsmeans;

run;