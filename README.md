****Predicting Rumen pH from Continuous Reticular pH Timcourse

Please note that as of 2016.1.11 the default dataset 'ph.dat' now includes
a datetime variable (date_time) and is read in the following order:

date_time animal day silage dmi time tc rumenph reticph

When exporting date_time to data files for later use in SAS, it need to be
converted back to numeric format using the best16. in the datastep (i.e. 
put date_time best16. animal day etc.)
