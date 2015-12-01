title 'Rumen pH Prediction - PDLREG';

/* Set output character width to 80 */
options linesize=80;

/* Data translation */
data read;
    infile 'ph.dat';
    input day animal silage dmi time rumenph reticph;
    oldreticph=reticph;
    oldrumenph=rumenph;

    if animal ne 52 then delete;
    if day ne 1 then delete;

proc pdlreg data=read;
    by animal day;

    /* Lag distribution specification in the form of regressor-name(length,
    degree, minimum-degree, end-constraint), where:

        length is the length of the lag distribution (i.e. the number of lags of
        the regressor to use)

        degree is the degree of the distribution polynomial

        minimum-degree is a optional minimum degree for the distribution

        end-constraint is an optional endpoint restriction specification

    If the minimum-degree option is specified, the procedure estimates models
    for all degrees between minimum-degree and degree */

    /* nlag specifies the order of the autoregressive process or the subset of
    autoregressive lags to be fit. If nlag is not specified, the procedure does
    not fit an autoregressive model */

    model rumenph=reticph(12,10,1) / nlag=10 backstep method=ml;
    output out=new p=pred rm=residph transform=rumenph transform=reticph;
run;

proc export
	data=new
	outfile="phregdev.xls"
	dbms=xls
	replace;
	sheet="pdlreg";