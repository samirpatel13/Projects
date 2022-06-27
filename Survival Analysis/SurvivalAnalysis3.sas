libname sa "C:/Users/samir/Documents/Courses/Survival Analysis/Data";

data hurricane;
	set sa.hurricane;
	if reason = 2 then motor = 1;
	else motor = 0;
	age2 = age**2;
	age3 = age**3;
	slope2 = slope**2;
	slope3 = slope**3;
	trashrackh = trashrack * hour;
	ID = _N_;
run;

/*** checking assumptions ***/

/* Linearity, slope breaks assumption looks cubic.  */
proc phreg data = hurricane;
	model hour*motor(0) = age backup bridgecrane elevation gear servo slope slope2 trashrack/ ties = efron;
	assess var=(age elevation slope2) / resample;
run;


/* proportional hazards, trashback breaks assumption fix with identify transformation */
proc phreg data=hurricane;
	model hour*motor(0) = age backup bridgecrane elevation gear servo slope slope2 trashrack/ ties = efron;
	assess ph / resample;
run;





/* backward selection of variables */
proc phreg data=hurricane;
	model hour*motor(0) = age backup bridgecrane elevation gear servo slope slope2 trashrack trashrackh run12
	/ ties=efron selection=backward sls=0.03;
	array h(*) h1-h48;
	hour_lag = h[hour] + h[hour-1]+ h[hour-2]+ h[hour-3]+ h[hour-4]+ h[hour-5]+ h[hour-6]+ h[hour-7]+ h[hour-8]+ h[hour-9]+ h[hour-10]+ h[hour-11];
	if hour_lag = 12 then run12 = 1;
	else run12=0;
run;


/* final model */

proc phreg data=hurricane;
	model hour*motor(0) = age slope slope2;
run;


/*** old
proc phreg data=hurricane;
	model hour*motor(0) = age backup bridgecrane elevation gear servo slope trashrack /
	ties=efron risklimits=pl selection=backward alpha=.03;
	array hr(*) h1-h48;
	motor = hr[hour];
	assess ph var=(age slope) / resample;
run;


proc phreg data=hurricane;
	model hour*motor(0) = age slope /
	ties=efron risklimits=pl selection=backward alpha=.03 ;
	array hr(*) h1-h48;
	motor = hr[hour];
run;
***/