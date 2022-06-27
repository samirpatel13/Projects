libname sa "C:/Users/samir/Documents/Courses/Survival Analysis/Data";

data hurricane;
	set sa.hurricane;
run;

proc print data=hurricane (obs=10);
run;
/*** percent of pumps that survived the hurricane ***/
proc freq data=hurricane;
	table survive;
run;

/*** Percentage of pumps in each type of failure and average failure time for each failure
type. ***/

proc freq data=hurricane;
	table survive;
	by reason;
run;

proc means data=hurricane mean median;
	class reason;
	var hour;
	output out=failuretime median=median mean=mean;
run;

data failuretime;
	set failuretime;
	if _type_ = 0 then delete;
	if reason = 0 then delete;
run;

/*** anova for to see if the means for hour is different across reason ***/
proc anova data=hurricane;
	where reason ne 0;
	class reason;
	model hour = reason;
run;

/*** npar1way to see if the medians for hour is different across reason ***/
proc npar1way data=hurricane median;
	where reason ne 0;
	class reason;
	var hour;
run;
	

/*** surivval graphs not by type ***/

proc lifetest data=hurricane;
	time hour*survive(1);
run;

/*** survival graphs by type ***/
proc lifetest data=hurricane;
	strata reason;
	time hour*survive(1);
run;

/*** conditional probability not by type ***/

proc lifetest data = hurricane method = life width = 1
plots=hazard;
time hour*survive(1);
ods output LifetableEstimates = condprob;
run;

proc sgplot data = condprob;
series x = lowertime y = condprobfail;
xaxis label='Tenure';
title 'Hazard Probability Function';
run;
quit;


/*** condiitonal probabilities by type ***/
proc lifetest data = hurricane method = life width = 1
plots=hazard;
strata reason;
time hour*survive(1);
ods output LifetableEstimates = condprob1;
run;

proc sgplot data = condprob1;
series x = lowertime y = condprobfail / group=reason;
xaxis label='Tenure';
title 'Hazard Probability Function';
run;
quit;

/*** last question ***/
proc lifetest data = hurricane plots=s(cb=ep);
time hour*survive(1);
strata reason;
run;







	
