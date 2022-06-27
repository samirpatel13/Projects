/*************************************************************************************************
Programmer: Samir Patel
Date: 1/31/20
Assignment: Optimization Project
*************************************************************************************************/
/*** Importing Data ***/
proc import datafile="C:\Users\samir\Documents\Courses\Optimization\ProjectData\STX.csv" dbms=csv out=STX replace; run;
proc import datafile="C:\Users\samir\Documents\Courses\Optimization\ProjectData\AMD.csv" dbms=csv out=AMD replace; run;
proc import datafile="C:\Users\samir\Documents\Courses\Optimization\ProjectData\IT.csv" dbms=csv out=IT replace; run;
proc import datafile="C:\Users\samir\Documents\Courses\Optimization\ProjectData\NOW.csv" dbms=csv out=NOW replace; run;
proc import datafile="C:\Users\samir\Documents\Courses\Optimization\ProjectData\FTV.csv" dbms=csv out=FTV replace; run;


/*** only keeping relevant variables ***/
data STX; set STX; rename close = STX; keep Date close; run;
data AMD; set AMD; rename close = AMD; keep Date close; run;
data IT; set IT; rename close = IT; keep Date close; run;
data NOW; set NOW; rename close = NOW; keep Date close; run;
data FTV; set FTV; rename close = FTV; keep Date close; run;

/*** Merging data ***/
data master;
	merge STX AMD IT NOW FTV;
	by date;
run;


/*** creating the return values ***/
data returns;
	set master;
	STXr = dif(STX);
	AMDr = dif(AMD);
	ITr = dif(IT);
	NOWr = dif(NOW);
	FTVr = dif(FTV);
	keep Date STXr AMDr ITr NOWr FTVr;
	if STXr = . then delete;
run;

/*** covariance and correlation information ***/
proc corr data=returns cov out=corr;
	var STXr AMDr ITr NOWr FTVr;
run;

data cov;
	set corr;
	where _TYPE_ = 'COV';
run;

data mean;
	set corr;
	where _TYPE_ = 'MEAN';
run;


proc optmodel;

	/* Declare Sets and Parameters */
	set <str> Assets1, Assets2, Assets3;
	num Covariance{Assets1,Assets2};
	num Mean{Assets1};

	/* Read in SAS Data Sets */
	read data Cov into Assets1=[_NAME_];
	read data Cov into Assets2=[_NAME_] {i in Assets1} <Covariance[i,_NAME_]=col(i)>;
	read data Mean into Assets3=[_NAME_] {i in Assets1} <Mean[i]=col(i)>;

	/* Declare Variables */
	var Proportion{Assets1}>=0 init 0;

	/* Declare Objective Function */
	min Risk = sum{i in Assets1}(sum{j in Assets1}Proportion[i]*Covariance[i,j]*Proportion[j]);

	/* Declare Constraints */
	con Return: 0.05 <= sum{i in Assets1}Proportion[i]*Mean[i];
	con Sum: 1 = sum{i in Assets1}Proportion[i];
	*con RisklessReturn: 0.015 <= sum{i in Assets1}Proportion[i]*Mean[i] + (1 - sum{i in Assets1}Proportion[i])*0.005;

	/* Call the Solver */
	solve;

	/* Print Solutions */
	print Covariance Mean;
	print Proportion 'Sum ='(sum{i in Assets1}Proportion[i]);

quit;


 proc means data=returns mean noprint;
 var STXr AMDr ITr NOWr FTVr;
 output out=_expected_daily_returns_(drop=_type_ _freq_) mean=;
 run; 

/*** Frointer ***/

/**************************** PROGRAM BEGINS HERE ****************************
  Read in stocks_r.csv into stocks                                         */



%let stocks= STXr AMDr ITr NOWr FTVr;


/*Create daily returns*/
  data _returns_;
  set returns;
  month=month(date);
  year=year(date);
  day = day(date);
  run;
proc sort data= _returns_;
by year month day;
run;

data _returns_;
 set _returns_;
 run;

proc means data=_returns_ sum noprint;
  var &stocks;
  by year month day;
  output out=daily_returns(drop=_type_ _freq_)  sum=&stocks;
  run;

/*Get the expected value of daily returns*/
  proc means data=daily_returns mean noprint;
  var &stocks;
  output out=_expected_daily_returns_(drop=_type_ _freq_) mean=;
  run; 
  proc transpose data=_expected_daily_returns_ 
        out=_expected_daily_returns_(rename=(Col1=daily_return));
  run;

/*Get the covariance matrix of daily returns*/
  proc corr data=daily_returns cov out=_cov_daily_returns_ noprint;
  var &stocks;
  run;
  data _cov_daily_returns_(drop=_type_);
  set _cov_daily_returns_(where=(_type_ = "COV"));
  run;

/*Use OPTMODEL to setup and solve the minimum variance problem*/ 
  proc optmodel printlevel=0 FDIGITS=8;
  set <str> Stock_Symbols; 

  /*DECLARE OPTIMIZATION PARAMETERS*/  
  /*Expected return for each stock*/
  num expected_return_stock{Stock_Symbols};      
  /*Covariance matrix of stocks*/ 
  num Covariance{Stock_Symbols,Stock_Symbols};
  /*Required portfolio return: PARAMETER THAT WE WILL ANALYZE*/ 
  num Required_Portfolio_Return;   
  /*Range of parameter values*/ 
  set parameter_values = {0.20 to 0.4 by 0.020}; 

  /*OUTPUT*/
  /*Array to hold the value of the objective function*/
  num Portfolio_Stdev_Results{parameter_values};  
  /*Array to hold the value of the exp. return*/
  num Expected_Return_Results{parameter_values};  
  /*Array to hold the value of the weights*/
  num Weights_Results{parameter_values,Stock_Symbols};  

  /* DECLARE OPTIMIZATION VARIABLES AND THEIR CONSTRAINTS*/
  /*Short positions are not allowed*/
  var weights{Stock_Symbols}>=0;    

  /* Declare implied variables (Optional)*/
  impvar exp_portf_return = sum{i in Stock_Symbols} expected_return_stock[i] * weights[i];

  /* Declare constraints */
  con c1: sum{i in Stock_Symbols} weights[i] = 1;
  con c2: exp_portf_return = Required_Portfolio_Return;

  /*READ INPUT DATA*/
  /*Read the expected daily returns. The first column, _name_ holds the    */
  /*index of stock symbols we want to use; that's why we include it with [].*/ 
  read data work._expected_daily_returns_ into Stock_Symbols=[_name_] expected_return_stock=daily_return;
  /*Read the covariance matrix*/       
  read data work._cov_daily_returns_ into [_name_] {j in Stock_Symbols} <Covariance[_name_,j]=col(j)>;

  /* DECLARE OBJECTIVE FUNCTION */ 
  min Portfolio_Stdev = 
     sqrt(sum{i in Stock_Symbols, j in Stock_Symbols}Covariance[i,j] * weights[i] * weights[j]);

  /*SOLVE THE PROBLEM FOR EACH PARAMETER VALUE*/
  for {r in parameter_values} do;
    /*Set the minimum portfolio return value to be used in each case*/
    Required_Portfolio_Return=r; 
    solve;
    /*Store the value of the objective function*/
    Portfolio_Stdev_Results[r]=Portfolio_Stdev; 
    /*Store the value of the expected returns*/ 
    Expected_Return_Results[r]=exp_portf_return;
    /*Store the weights*/
    for {i in Stock_Symbols} do;
      Weights_Results[r,i]=weights[i];
    end;
  end;

   /*Store the portfolio return and std.dev from all runs in a SAS dataset*/
   create data obj_value_stddev_results from 
         [parameter_values] Portfolio_Stdev_Results Expected_Return_Results;

   /*Store the weights from all runs in a SAS dataset*/ 
   create data min_stddev_weight_results from 
         [_param_ _stock_]={parameter_values , stock_symbols} Weights_Results;
quit;

/*Efficient Frontier*/
proc sgplot data=Obj_value_stddev_results;
series x=Portfolio_Stdev_Results y=expected_return_results;
quit;



/*** Plots ***/

proc sgplot data=returns;
	series x=date y=STXr;
run;
proc sgplot data=returns;
	series x=date y=AMDr;
run;
proc sgplot data=returns;
	series x=date y=FTVr;
run;
proc sgplot data=returns;
	series x=date y=ITr;
run;
proc sgplot data=returns;
	series x=date y=NOWr;
run;

proc sgplot data=returns;
	series x=date y=STXr;
	series x=date y=AMDr;
	series x=date y=FTVr;
	series x=date y=ITr;
	series x=date y=NOWr;
run;


proc sgplot data=master;
	series x=date y=STX;
run;
proc sgplot data=master;
	series x=date y=AMD;
run;
proc sgplot data=master;
	series x=date y=FTV;
run;
proc sgplot data=master;
	series x=date y=IT;
run;
proc sgplot data=master;
	series x=date y=NOW;
run;