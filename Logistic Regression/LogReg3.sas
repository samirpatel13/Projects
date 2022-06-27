/******************************************************************************************************
Programmer: Samir Patel
Date: 9/11/2019
Assignment: Logistic Regression 2
******************************************************************************************************/

libname logr "C:/Users/samir/Documents/Classdata/LogRegHmwkData";

data logreg2;
	set logr.insurance_t_bin;
run;

proc print data=logreg2 (obs=100);
run;

%let predictors = DDA	CASHBK	DIRDEP	NSF	SAV	ATM	CD	IRA	LOC	ILS	MM	MMCRED	MTG	SDB	MOVED	
				INAREA	BRANCH	RES	DDABAL_Bin	ACCTAGE_Bin	DEPAMT_Bin	CHECKS_Bin	NSFAMT_Bin	
				PHONE_Bin	TELLER_Bin	SAVBAL_Bin	ATMAMT_Bin	POS_Bin	POSAMT_Bin	CDBAL_Bin	
				IRABAL_Bin	LOCBAL_Bin	INVBAL_Bin	ILSBAL_Bin	MMBAL_Bin	MTGBAL_Bin	CCBAL_Bin	
				INCOME_Bin	LORES_Bin	HMVAL_Bin AGE_Bin	CRSCORE_Bin	INV2 CC2 CCPURC2 HMOWN2;
/******************************************************************************************************
* Objective 1: For any variable with missing values, change the data to include a missing category    *
* instead of a missing value for the categorical variable                                             *
******************************************************************************************************/

/*** check to see which variables have missing values ***/
proc means data=logreg2 nmiss;
run;
/*** INV, CC, CCPURC, HMOWN all have missing values. Create new variables as INV2, CC2, CCPURC2, HMOWN2
	 with recode set as a missing flag***/

data logreg2;	
	set logreg2;
	INV2 =put(INV,1.);
	CC2 = put(CC,1.);
	CCPURC2 = put(CCPURC,1.);
	HMOWN2 = put(HMOWN,1.);
	if INV2 = . then INV2 = "M";
	if CC2 = . then CC2 = "M";
	if CCPURC2 = . then CCPURC2 = "M";
	if HMOWN2 = . then HMOWN2 = "M";
	drop INV CC CCPURC HMOWN;
run;

data logreg3valid;	
	set logr.insurance_v_bin;
	INV2 =put(INV,1.);
	CC2 = put(CC,1.);
	CCPURC2 = put(CCPURC,1.);
	HMOWN2 = put(HMOWN,1.);
	if INV2 = . then INV2 = "M";
	if CC2 = . then CC2 = "M";
	if CCPURC2 = . then CCPURC2 = "M";
	if HMOWN2 = . then HMOWN2 = "M";
	drop INV CC CCPURC HMOWN;
run;
/*** check to see if values have been recoded correctly and checking for complete seperation ***/
/******************************************************************************************************
*  Objective 2:Check each variable for separation concerns. Document in the report and adjust any     *
*  variables with complete or quasi-separation concerns                                               *
******************************************************************************************************/
proc freq data=logreg2 nlevels;
	tables INS*(&predictors.) / nocol norow nocum nopercent;
run;

/*************************************************
*Complete Seperation:                            *
*Quasai Complete Seperation: CASHBK MMCRED       *
                                                 *
Solution: Recode CASHBK = 2 to CASHBK = 1        *
		  Recode MMCRED = 5 to MMCRED = 3        *
*************************************************/

proc freq data=logreg2;
	tables INS*(CASHBK MMCRED);
run;

data logreg2;
	set logreg2;
	if CASHBK = 2 then CASHBK = 1;
	if MMCRED = 5 then MMCRED = 3;
run;

proc freq data=logreg2;
	tables INS*(CASHBK MMCRED);
run;


/******************************************************************************************************
*Objective 3: Use backward selection to do the variable selection – the Bank currently uses           *
* alpha = 0.002and p-values to perform backward, but is open to another technique and/or significance *
* level if documented in your report.                                                                 *
*Objective 4: Report the final variables from this model ranked by p-value.                           *
******************************************************************************************************/

proc logistic data=logreg2 plots(only)=(oddsratio);
	class &predictors. / param=ref;
	model INS(event='1') = &predictors. / selection=backward slstay = .002
										  clodds = pl clparm = pl;
run;

%let sigpred = DDA	NSF	IRA	ILS	MM	BRANCH	DDABAL_Bin	CHECKS_Bin	TELLER_Bin	
			   SAVBAL_Bin	ATMAMT_Bin	CDBAL_Bin	INV2	CC2;




/******************************************************************************************************
* Objective 6: Investigate possible interactions using forward selection including only the main      *
* effects from your previous final model. DDABAL_BIN*SAVBAL_Bin MM*DDABAL_Bin DDA*IRA are sig.		  *
******************************************************************************************************/


proc logistic data=logreg2 plots(only)=(oddsratio);
	class &sigpred.;
	model INS(event='1') = &sigpred. DDA|NSF|IRA|ILS|MM|BRANCH|DDABAL_Bin|CHECKS_Bin|Teller_Bin
									 |SAVBAL_Bin|ATMAMT_Bin|CDBAL_Bin|INV2|CC2 @2 / selection=forward slentry=.002;
run;



/*** Checking for any seperation problems in significant interactions, no seperation issues found. ***/
proc freq data=logreg2;
	tables DDABAL_BIN*SAVBAL_Bin MM*DDABAL_Bin DDA*IRA;
run;



/**** MISC STUFF ****/
/***** Model creation using AIC Criteria ***/

proc logistic data=logreg2 plots(only)=(oddsratio);
	class &predictors. / param=ref;
	model INS(event='1') = &predictors. / selection=backward slstay = .1573
										  clodds = pl clparm = pl;
run;



%let sigpred = DIRDEP	NSF	SAV	IRA	LOC	ILS	MM	MTG	BRANCH	DDABAL_Bin	CHECKS_Bin	NSFAMT_Bin	
			   TELLER_Bin	SAVBAL_Bin	ATMAMT_Bin	CDBAL_Bin	INCOME_Bin	HMVAL_Bin	INV2	CC2;
%let sigpred = SAVBAL_BIN DDABAL_BIN CDBAL_BIN MM CHECKS_BIN ATMAMT_BIN CC2 TELLER_BIN DDA IRA INV2 ILS 
			   MTG NSF DDA*IRA;

proc logistic data=logreg2 plots(only)=(oddsratio);
	class &sigpred.;
	model INS(event='1') = &sigpred. DIRDEP|NSF|SAV|IRA|LOC|ILS|MM|MTG|BRANCH|DDABAL_Bin
									 |CHECKS_Bin|NSFAMT_Bin|TELLER_Bin|SAVBAL_Bin|ATMAMT_Bin
									 |CDBAL_Bin|INCOME_Bin|HMVAL_Bin|INV2|CC2 @2 / selection=forward slentry=.1573;
run;


%let sigpred = DDA NSF IRA ILS MM MTG DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN ATMAMT_BIN CDBAL_BIN
			   INV2 CC2;


proc logistic data=logreg2 plots(only)=(oddsratio);
	class &sigpred./param=effect;
	model INS(event='1') = &sigpred. DDA*IRA;
run;

/****************************************************************************************************/


/*** Log reg 3 ***/


/******************************************************************************************************
* Objective 2: Report and interpret the following probability metrics for your model on training data.*
* o Concordance percentage.                                                                           *
* o Discrimination slope – provide the coefficient of discrimination as well as a visual              *
* representation through histograms.                                                                  *
******************************************************************************************************/
%let sigpred = SAVBAL_BIN DDABAL_BIN CDBAL_BIN MM CHECKS_BIN ATMAMT_BIN CC2 TELLER_BIN DDA IRA INV2 ILS 
			   MTG NSF;

proc logistic data=logreg2 plots(only)=(oddsratio);
	class &sigpred.;
	model INS(event='1') = &sigpred. DDA*IRA/ ctable pprob = 0 to .98 by .02;
	output out=predprobs p=phat;										
run;


proc sort data=predprobs;
	by descending INS;
run;

proc ttest data=predprobs order=data;
	ods select statistics summarypanel;
	class INS;
	var phat;
	title 'Coefficient of Discrimination and Plots';
run;

/*********************************************************************************************************
* Objective 3: Report and interpret the following classification metrics for your model on training data.*
* o Visually show the ROC curve.                                                                         *
* (HINT: Although this is one of the only times I will allow SAS output in a report,                     *               
* make sure the axes and title are well labeled.)                                                        *
* o K-S Statistic. The Bank currently uses the K-S statistic to choose the threshold for                 *
* classification but are open to other methods as long as they are documented in the                     *
* report and defended.                                                                                   *
*********************************************************************************************************/

proc logistic data=logreg2 plots(only)=(roc);
	class &sigpred.;
	model INS(event='1') = &sigpred. DDABAL_Bin*SAVBAL_Bin MM*DDABAL_Bin DDA*IRA / clodds = pl clparm = pl;
	output out=predprobs p=phat;										
run;

proc npar1way data=predprobs d plot=edfplot;
	class INS;
	var phat;
run;


/***********************************************************************************************************
* Objective 4: Report and interpret the following classification metrics for your model on validation data.*
* o Display your final confusion matrix.                                                                   *
* o Accuracy.                                                                                              *    
* o Lift – add a visual to help show the model performance.                                                *
***********************************************************************************************************/

proc logistic data=logreg2 plots(only)=(roc);
	class &sigpred.;
	model INS(event='1') = &sigpred. DDABAL_Bin*SAVBAL_Bin MM*DDABAL_Bin DDA*IRA / clodds = pl clparm = pl ctable pprob = 0 to 0.98 by 0.02;
	output out=predprobs p=phat;	
	ods output classification=classtable;
run;





























