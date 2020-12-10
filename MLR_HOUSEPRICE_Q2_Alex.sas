/*
Importing the train and test data
*/
proc import datafile = "U:\Houseprice\train.csv"
		out=train
		dbms=CSV
		REPLACE;
		getnames=yes;
run;
proc import datafile = "U:\Houseprice\test.csv"
		out=test
		dbms=CSV
		REPLACE;
		getnames=yes;
run;
/*
Variable selection techniques:
Based on personal knowledge, we selected 10 variables that we thought would impact the price of a house.  First, creating two new columns , Total_Bath
and Pool_yn
*/
data train;
	set train;	
Total_Bath = FullBath+HalfBath;
run;
data test;
	set test;
Total_Bath = FullBath+HalfBath;
run;
/*
Formatting variables that have a string datatype, filling missing data in GarageCars, Converting Central Air and Pool Area to Yes/No, 
*/
proc sql;
  create table house_price_train as
    select Id, SalePrice, GrLivArea, Neighborhood, LotArea, Total_Bath, BedroomAbvGr, YearRemodAdd,BldgType, CentralAir,
        case when PoolArea = 0 then 0 else 1 end as Pool_yn,
        case when GarageCars is missing then 0 else GarageCars end as GarageCars,
        case when Neighborhood ='CollgCr' then 25
        when Neighborhood ='Veenker' then 24
        when Neighborhood ='Crawfor' then 23
        when Neighborhood ='NoRidge' then 22
        when Neighborhood ='Mitchel' then 21
        when Neighborhood ='Somerst' then 20
        when Neighborhood ='NWAmes' then 19
        when Neighborhood ='OldTown' then 18
        when Neighborhood ='BrkSide' then 17
        when Neighborhood ='Sawyer' then 16
        when Neighborhood ='NridgHt' then 15
        when Neighborhood ='NAmes' then 14
        when Neighborhood ='SawyerW' then 13
        when Neighborhood ='IDOTRR' then 12
        when Neighborhood ='MeadowV' then 11
        when Neighborhood ='Edwards' then 10
        when Neighborhood ='Timber' then 9
        when Neighborhood ='Gilbert' then 8
        when Neighborhood ='StoneBr' then 7
        when Neighborhood ='ClearCr' then 6
        when Neighborhood ='NPkVill' then 5
        when Neighborhood ='Blmngtn' then 4
        when Neighborhood ='BrDale' then 3
        when Neighborhood ='SWISU' then 2
        when Neighborhood ='Blueste' then 1
        else 0 end as Neighborhood_num,
        case when CentralAir = 'Y' then 1 else 0 end as CentralAir_YN,
        case when BldgType = '1Fam' then 1
        when BldgType = '2fmCon' then 2
        when BldgType = 'Duplex' then 3
        when BldgType = 'TwnhsE' then 4
        when BldgType = 'Twnhs' then 5
        else 0 end as BldgType_num
    from train;
run;
proc sql;
  create table house_price_test as
    select Id, GrLivArea, Neighborhood, LotArea, Total_Bath, BedroomAbvGr, YearRemodAdd,BldgType, CentralAir,
        case when PoolArea = 0 then 0 else 1 end as Pool_yn,
        case when GarageCars is missing then 0 else GarageCars end as GarageCars,
        case when Neighborhood ='CollgCr' then 25
        when Neighborhood ='Veenker' then 24
        when Neighborhood ='Crawfor' then 23
        when Neighborhood ='NoRidge' then 22
        when Neighborhood ='Mitchel' then 21
        when Neighborhood ='Somerst' then 20
        when Neighborhood ='NWAmes' then 19
        when Neighborhood ='OldTown' then 18
        when Neighborhood ='BrkSide' then 17
        when Neighborhood ='Sawyer' then 16
        when Neighborhood ='NridgHt' then 15
        when Neighborhood ='NAmes' then 14
        when Neighborhood ='SawyerW' then 13
        when Neighborhood ='IDOTRR' then 12
        when Neighborhood ='MeadowV' then 11
        when Neighborhood ='Edwards' then 10
        when Neighborhood ='Timber' then 9
        when Neighborhood ='Gilbert' then 8
        when Neighborhood ='StoneBr' then 7
        when Neighborhood ='ClearCr' then 6
        when Neighborhood ='NPkVill' then 5
        when Neighborhood ='Blmngtn' then 4
        when Neighborhood ='BrDale' then 3
        when Neighborhood ='SWISU' then 2
        when Neighborhood ='Blueste' then 1
        else 0 end as Neighborhood_num,
        case when CentralAir = 'Y' then 1 else 0 end as CentralAir_YN,
        case when BldgType = '1Fam' then 1
        when BldgType = '2fmCon' then 2
        when BldgType = 'Duplex' then 3
        when BldgType = 'TwnhsE' then 4
        when BldgType = 'Twnhs' then 5
        else 0 end as BldgType_num
    from test;
run;
/*Looking at the Scatter for all variables*/
proc sgscatter data=house_price_train;
  title "Scatterplot Matrix for House data";
  matrix SalePrice GrLivArea Neighborhood_num LotArea Total_Bath BedroomAbvGr GarageCars YearRemodAdd BldgType_num;
run;
/*Looking at the scatter plots for variables we have identified for a log transformation*/
proc sgscatter data=house_price_train;
  title "Scatterplot Matrix for House data";
  matrix SalePrice GrLivArea LotArea;
run;
/*Log transforming variables and adding them to each data set*/
data loghouseprice;
	set house_price_train;
	logSalePrice = log(SalePrice);
	logGrLivArea = log(GrLivArea);
	logLotArea = log(LotArea);
run;	
data loghousepricetest;
	set house_price_test;
	logSalePrice = log(SalePrice);
	logGrLivArea = log(GrLivArea);
	logLotArea = log(LotArea);
run;		
/*Exploring relationship of transformed variables*/
proc sgscatter data=loghouseprice;
  title "Scatterplot Matrix for House data";
  matrix logSalePrice logGrLivArea logLotArea;
run;
/* Below is the stepwise selection model and predictions*/
proc glmselect data = loghouseprice plots=all;
model logSalePrice = logGrLivArea Neighborhood_num logLotArea Total_Bath BedroomAbvGr GarageCars YearRemodAdd BldgType_num /
selection = stepwise (choose = bic stop = bic);
score data=loghousepricetest out=Pred;
run;
*Selected variables are: Intercept logGrLivArea Neighborhood_num logLotArea Total_Bath BedroomAbvGr GarageCars YearRemodAdd *;

/*Observing the predictions made*/
proc print data=Pred;
run;
/*Selecting the columns needed for submission*/
proc sql;
  create table Pred_Submission as
    select Id,
    exp(p_logSalePrice) as SalePrice
    from Pred;
run;
/*Exporting the Submission File into a CSV for submission*/
PROC EXPORT 
DATA=Pred_Submission  
DBMS=csv 
LABEL 
OUTFILE= "U:\Houseprice\Pred_Submission_Stepwise.csv"
REPLACE;

/* AIC seems more appropriate if there are not too many redundant
and unnecessary X’s in the starting set; BIC seems more appropriate if there are
many redundant and unnecessary */


*Internal CV: the smallest CVPRESS has the highest predictive power*;
proc glmselect data = loghouseprice plots(stepaxis = number) = (criterionpanel ASEPLOT);
model logSalePrice = logGrLivArea Neighborhood_num logLotArea Total_Bath BedroomAbvGr GarageCars YearRemodAdd BldgType_num/
selection = stepwise (select=cv choose = cv stop = cv) CVDETAILS;
run;

/* Below is the Forward selection model and predictions*/
proc glmselect data = loghouseprice plots=all;
model logSalePrice = logGrLivArea Neighborhood_num logLotArea Total_Bath BedroomAbvGr GarageCars YearRemodAdd BldgType_num /
selection = forward (select = cv choose = bic stop = bic) CVDETAILS;
score data=loghousepricetest out=Pred;
run;
*Final selection is: Intercept logGrLivArea Neighborhood_num logLotArea Total_Bath BedroomAbvGr GarageCars YearRemodAdd;
/*Observing the predictions made*/

/* Below is the Backward selection model and predictions*/
proc glmselect data = loghouseprice plots=all;
model logSalePrice = logGrLivArea Neighborhood_num logLotArea Total_Bath BedroomAbvGr GarageCars YearRemodAdd BldgType_num /
selection = backward (select = cv choose = bic stop = bic) CVDETAILS;
score data=loghousepricetest out=Pred;
run;
*Final selection is the same as forward selection*;
/*Observing the predictions made*/
proc print data=Pred (obs = 5);
run;
/*Selecting the columns needed for submission*/
proc sql;
  create table Pred_Submission as
    select Id,
    exp(p_logSalePrice) as SalePrice
    from Pred;
run;
/*Exporting the Submission File into a CSV for submission*/
PROC EXPORT 
DATA=Pred_Submission  
DBMS=csv 
LABEL 
OUTFILE= "U:\Houseprice\Pred_Submission_Forward.csv"
REPLACE;
*Internal CV: the smallest CVPRESS has the highest predictive power*;
proc glmselect data = loghouseprice plots(stepaxis = number) = (criterionpanel ASEPLOT);
model logSalePrice = logGrLivArea Neighborhood_num logLotArea Total_Bath BedroomAbvGr GarageCars YearRemodAdd BldgType_num/
selection = forward (select=cv choose = cv stop = cv) CVDETAILS;
run;
/* Below is the Backward selection model and predictions*/
proc glmselect data = loghouseprice plots=all;
model logSalePrice = logGrLivArea Neighborhood_num logLotArea Total_Bath BedroomAbvGr GarageCars YearRemodAdd BldgType_num /  selection = backward;
score data=loghousepricetest out=Pred;
run;
/*Observing the predictions made*/
proc print data=Pred (obs = 5);
run;
/*Selecting the columns needed for submission*/
proc sql;
  create table Pred_Submission as
    select Id,
    exp(p_logSalePrice) as SalePrice
    from Pred;
run;
/*Exporting the Submission File into a CSV for submission*/
PROC EXPORT 
DATA=Pred_Submission  
DBMS=csv 
LABEL 
OUTFILE= "U:\Houseprice\Pred_Submission_Backward.csv"
REPLACE;
*Internal CV: the smallest CVPRESS has the highest predictive power*;
proc glmselect data = loghouseprice plots(stepaxis = number) = (criterionpanel ASEPLOT);
model logSalePrice = logGrLivArea Neighborhood_num logLotArea Total_Bath BedroomAbvGr GarageCars YearRemodAdd BldgType_num/
selection = backward (select=cv choose = cv stop = cv) CVDETAILS;
run;
/*Post selection, below is the actual regression model*/
proc reg data = loghouseprice plots=dignostics(stats=(default aic bic cp rsquare));
model logSalePrice = logGrLivArea Neighborhood_num logLotArea Total_Bath BedroomAbvGr GarageCars YearRemodAdd;
run;

proc glm data = loghouseprice;
class Neighborhood_num (ref = 14);
model logSalePrice = logGrLivArea logLotArea Total_Bath BedroomAbvGr GarageCars YearRemodAdd BldgType_num Neighborhood_num  / solution clparm;
run;
