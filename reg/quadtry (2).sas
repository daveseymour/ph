options linesize=80; /* nodate nonumber formdlim=" "; */
data read;
        infile 'ph.dat';
        input day animal silage dmi time rumenph reticph;

/*
if animal ne 52 then delete;
if day ne 1 then delete;
*/

time2=time**2;
time3=time**3;
time4=time**4;

proc reg data=read noprint;
     by animal day;
     model reticph=time time2 time3 time4;
     output out=new p=pred r=resid;

/*
proc pdlreg data=read;
     model rumenph=reticph(3,1) / nlag=1 dwprob;
*/

data new2 (drop=i count);
     set new;
     by animal day;
     array x(*) lagretic1-lagretic9;
     array y(*) lagpred1-lagpred9;
     array z(*) lagresid1-lagresid9;
     lagretic1=lag1(reticph);
     lagretic2=lag2(reticph);
     lagretic3=lag3(reticph);
     lagretic4=lag4(reticph);
     lagretic5=lag5(reticph);
     lagretic6=lag6(reticph);
     lagretic7=lag7(reticph);
     lagretic8=lag8(reticph);
     lagretic9=lag9(reticph);
     predsq=pred**2.0;
     lagpred1=lag1(pred);
     lagpred2=lag2(pred);
     lagpred3=lag3(pred);
     lagpred4=lag4(pred);
     lagpred5=lag5(pred);
     lagpred6=lag6(pred);
     lagpred7=lag7(pred);
     lagpred8=lag8(pred);
     lagpred9=lag9(pred);
     lagresid1=lag1(resid);
     lagresid2=lag2(resid);
     lagresid3=lag3(resid);
     lagresid4=lag4(resid);
     lagresid5=lag5(resid);
     lagresid6=lag6(resid);
     lagresid7=lag7(resid);
     lagresid8=lag8(resid);
     lagresid9=lag9(resid);
     if first.day then count=1;
     do i=count to 9;
     	x(i)=.;
	y(i)=.;
	z(i)=.;
     end;
     count+1;
     drop time2 time3 time4;

/*
proc pdlreg data=new2;
     model rumenpH=pred(3,1) lag7resid(4,1) / dwprob;

proc autoreg data=new2;
     model rumenph=pred lag1pred lag3pred lag5pred lag1resid lag7resid / dwprob;
*/

proc reg data=new2 outest=est;
     model rumenph=pred lagpred1 lagpred2 lagpred3 lagpred4 lagpred5 lagpred6 lagpred7 lagpred8 lagpred9
     	   resid lagresid1 lagresid2 lagresid3 lagresid4 lagresid5 lagresid6 lagresid7 lagresid8 lagresid9
	   / selection=backward aic dwprob;
proc print data=est;
/*best backward selected model is rumenph=pred lagpred1 lagpred3 lagresid2 lagresid4 lagresid7 lagresid9*/


proc mixed data=new2;
     class animal day;
     model rumenph=pred lagpred1 lagresid2 lagresid7 lagresid9 / solution outp=preds;
     random intercept pred lagpred1 lagresid2 lagresid7 lagresid9 / type=un subject=animal*day;

/*
proc mixed data=new2;
     class animal day;
     model rumenph=reticph lagretic2 lagretic7/ solution outp=preds;
     random intercept reticph lagretic2 lagretic7 / type=un subject=animal*day;
*/


data biascorr;
     set preds;
     pred2sq=pred2**2;
     pred2cb=pred2**3;


proc mixed data=biascorr;
     class animal day;
     model resid2=pred2 pred2sq / solution;
     random intercept pred2 pred2sq / type=un subject=animal*day;


/*
ods csv file='finalpreds.csv';
proc print data=preds;
     var day animal time rumenph pred2 resid2;
run;
ods csv close;
*/


run;


