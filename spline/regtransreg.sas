options linesize=80;

title 'REG vs TRANSREG Model Fits';

data reg;
    infile '~/ph/resid/aormixed.dat';
    input animal day silage dmi time reticph Preticph Rreticph rumenph Prumenph
        Rrumenph lag1p lag3p lag2r lag4r lag7r lag9r;
    if animal = 52 and day > 12 then delete;
    tc = time + (day-1);
    time2 = time**2;
    time3 = time**3;
    time4 = time**4;
    tc2 = tc**2;
    tc3 = tc**3;
    tc4 = tc**4;
run;

data transreg;
    infile '~/ph/final/mixed.dat';
    input animal day silage dmi time tc reticph Preticph Rreticph rumenph
        Prumenph Rrumenph lag1p lag3p lag2r lag4r lag7r lag9r;
    if animal = 52 and day > 12 then delete;
run;

proc mixed data=reg covtest noitprint ic;
    title2 'PROC REG Model Fit';
    class animal day silage;
    model rumenph = reticph lag1p lag2r lag7r lag9r silage / solution
        outp=mixed;
    random intercept Preticph lag1p lag2r lag7r lag9r / type=un
        subject=animal*day;
run;

proc mixed data=transreg covtest noitprint ic;
    title2 'PROC TRANSREG Model Fit';
    class animal day silage;
    model rumenph = reticph lag1p lag2r lag7r lag9r silage / solution
        outp=mixed;
    random intercept Preticph lag1p lag2r lag7r lag9r / type=un
        subject=animal*day;
run;
