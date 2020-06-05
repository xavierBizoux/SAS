%global originStmt typeStmt driveTrainStmt invoiceStmt;

%macro generate; 
	%if %symexist(var_origin) %then %let originStmt = origin in ("&var_origin") and;  
	%if %symexist(var_type) %then %do;
		%let typeList = ;
		%if %symexist(var_type_count) %then 
		%do i=1 %to &var_type_count;
			%let typeList = "&&var_type&i", &typeList ;
		%end;
		%else %let typeList = "&var_type"; 
		%let typeStmt = type in (&typeList) and; 
	%end; 
	%if %symexist(var_driveTrain) %then %let driveTrainStmt = driveTrain in ("&var_driveTrain") and;
	%if %symexist(var_invoice) %then %let invoiceStmt = invoice < &var_invoice ; 
	%else %let invoiceStmt = invoice > 0;
%mend; 

%generate; 

proc print data=sashelp.cars; 
	where &originStmt  &typeStmt &driveTrainStmt &invoiceStmt; 
run;

