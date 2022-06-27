libname sa "C:/Users/samir/Documents/Courses/Survival Analysis/Data";

data hurricane;
	set sa.hurricane;
	if reason = 1 then flood = 1;
	else flood = 0;
	ID = _N_;
run;


/* bad distribution */
proc lifereg data=hurricane;
model hour*flood(0) = age backup bridgecrane elevation trashrack gear servo slope /
alpha= .03 dist=exponential;
probplot;
run;

/* best? distribution */
proc lifereg data=hurricane;
model hour*flood(0) = age backup bridgecrane elevation trashrack gear servo slope /
alpha= .03 dist=weibull;
probplot;
run;

/* okay distribution but weibull is better*/
proc lifereg data=hurricane;
model hour*flood(0) = age backup bridgecrane elevation trashrack gear servo slope /
alpha= .03 dist=gamma;
probplot;
run;

/* okay distribution */
proc lifereg data=hurricane;
model hour*flood(0) = age backup bridgecrane elevation trashrack gear servo slope / 
alpha= .03 dist=llogistic;
probplot;
run;

/* backward selection */
proc lifereg data=hurricane;
model hour*flood(0) = backup servo slope /
alpha= .03 dist=weibull;
probplot;
run;

/*** Backup upgrade***/

proc lifereg data=hurricane;
model hour*flood(0) = backup servo slope /
alpha= .03 dist=weibull;
output out=surv_q p=quan quantile=(0.25, 0.50, 0.75)
std_err=se;
run;

proc print data=surv_q;
var hour _PROB_ quan se;
run;




proc lifereg data=hurricane outest=Beta;
	model hour*flood(0) = backup servo slope / dist=weibull;
	output out=recid_e xbeta=lp cdf=cdistfunc;
run;

data _null_;
	set Beta;
	call symput('shape', 1/_SCALE_);
	call symput('beta_backup', backup);
	call symput('beta_servo', servo);
run;

/*** backup upgrade ***/
data recid_e1;
	set recid_e;
	if flood = 0 then delete;
	if backup = 1 then delete;
	survprob = 1 - cdistfunc;	
	lp_new = lp + &beta_backup;	
	newtime = squantile('weibull', survprob, &shape, exp(lp_new));
	diff = newtime - hour;
run;

proc print data=recid_e1;
	var ID survprob lp lp_new hour newtime diff;
run;

data backup_upgrade;	
	set recid_e1;
	cost_backup = 100000;
	keep id diff cost_backup;
run;

proc print data=backup_upgrade;
run;

/*** servo upgrade ***/
data recid_e2;
	set recid_e;
	if flood = 0 then delete;
	if servo = 1 then delete;
	survprob = 1 - cdistfunc;	
	lp_new = lp + &beta_servo;	
	newtime = squantile('weibull', survprob, &shape, exp(lp_new));
	diff2 = newtime - hour;
run;

proc print data=recid_e2;
	var ID survprob lp lp_new hour newtime diff2;
run;

data servo_upgrade;
	set recid_e2;
	cost_servo = 150000;
	keep id diff2 cost_servo;
run;
/*** combining upgrades so that we can see the most useful upgrades in terms of hours ***/
proc sort data=backup_upgrade; by id; run;
proc sort data=servo_upgrade; by id; run;

data upgrades;
	merge backup_upgrade servo_upgrade;
	by id;
	cost_per_hour_backup = cost_backup/diff;
	cost_per_hour_servo = cost_servo/diff2;
	rename diff=backup_upgrade 
		   diff2=servo_upgrade;
run;

proc print data=upgrades;
run;

proc transpose data=upgrades out=test prefix=cost name=type;
	by id;
	var cost_per_hour_backup cost_per_hour_servo;
run;

data test;
	set test;
	if type = 'cost_per_hour_backup' then upgrade_cost = 100000;
	else upgrade_cost = 150000;
	if cost1 ne .;
run;

proc sort data=test; by id cost1; run;

data test;
	set test;
	by id;
	if first.id;
run;

proc sort data=test; by cost1; run;

proc print data=test;
run;

proc sort data=backup_upgrade; by id; run;
proc sort data=test1; by id; run;
data test2;
	merge test1 (in=a) backup_upgrade(keep=id diff);
	by id;
	if a;
run;

proc sort data=servo_upgrade; by id; run;
data test3; 
	merge test2 (in=a) servo_upgrade(keep= id diff2);
	by id;
	if a;
run;

data test4; 
	set test3;
	if findw(type, 'cost_per_hour_servo') then difference = diff2;
	if findw(type, 'cost_per_hour_backup') then difference = diff;
	drop diff diff2;
run;

proc sort data=test4; by cost1; run;

data test5;
	set test4;
	total_cost + upgrade_cost;
	hours_gained + difference;
	drop total;
run;

proc print data=test5;
run;
	
