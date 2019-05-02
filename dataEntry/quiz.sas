/* Define macro variables for the parameters defined in the URL */
%global id maxid answer01 answer02 answer03 answer04 answer05;

/* Define CAS server connection, session and CAS libraries */
options cashost="intcas01.race.sas.com" casport=5570;
cas mySession sessopts=(caslib="casuser");
libname visual cas caslib="visual";
libname casuser cas caslib="casuser";

/* Macro invoked at the beginning of the Job execution */
%macro init;
	%if %symexist(id) and %eval(&id > 0) %then
		%do;

			/* Call record macro to register the answers */
		%record;

			/* Increment question id */
		%let id = %eval(&id + 1 );
		%end;
	%else
		%do;

			/* Code executed when loading the first time */
		%let id = 1;
			
			data casuser.questions; 
				set visual.quiz_programming; 
			run;
			proc cas; 
				table.promote /caslib="casuser" name="questions";
			quit;
		%end;

	/* Define the number of questions */
	proc sql noprint;
		create table maxid as select max(id) as maxid from casuser.questions;
		select maxid into :maxid from maxid;
	quit;

%mend;

/* Macro invoked when last question has been answered */
%macro finish;
	%if %eval(&id > &maxid) %then
		%do;
			/* Generate the data set to be loaded into the Global CASLib used for reporting */
			data casuser.toLoad;
				set casuser.questions (drop= questions choices hint justification);
				userid = "&sysuserid";
				datetime = datetime();
				format datetime datetime16.;
			run;
			/* Load data into the CASLib used for reporting and perform some cleanup activities */
			proc cas;
				table.tableExists result=res/caslib='visual' name='quiz_answers';
				
				if res.exists > 0 then
				do;
					datastep.runcode result=dsResult /code="data visual.quiz_answers (append=yes); set casuser.toLoad; run;";
				end;
				else
				do;
					table.promote / caslib='casuser' name='toLoad' target='quiz_answers' targetlib='visual';
					table.promote / caslib='visual' name='quiz_answers';
				end;
				table.save / caslib='visual' name='quiz_answers' table={caslib='visual' name='quiz_answers'} replace=true;
				table.dropTable / caslib='casuser' name='questions';
				table.deleteSource / caslib='casuser' source='questions';
				table.dropTable / caslib='casuser' name='toLoad';
				table.deleteSource / caslib='casuser' source='toLoad';
			quit;
			/* Terminate the CAS session */
			cas mySession terminate;
		%end;
%mend;

/* Macro invoked to record the answers */
%macro record;
	proc cas;
		questionsTbl.name="questions";

		do i=1 to 5 by 1;
			name_i=put(i, z2.);
			varName='Answer'||name_i;

			if symget(varName) > "" then
				do;
					questionsTbl.where="&id = id and name ='"|| varName ||"'";
					table.update / table=questionsTbl set={{var='selected', value="1"}};
				end;
		end;
	quit;

%mend;

/*Macro generating the html pages */
%macro html;
	%if %eval(&id > &maxid) %then
		%do;
	/* Call the quiz summary page */
			%html_result;
		%end;
	%else
		%do;

			data _null_;
				set casuser.questions (where=(ID=&id)) nobs=rows;
				file _webout;
				by id;
				/* Generate the HTML head */
				if _n_ = 1 then do;
					put '<html lang="en">';
					put '<head>';
					put '<title>quiz Programming</title>';
					put '<meta charset="utf-8">';
					put '<meta name="viewport" content="width=device-width, initial-scale=1.0">';
					put '<meta author="BIZOUX, Xavier">';
					put '<style>';
					put 'article {padding-left:20px;}';
					put '</style>';
					put '<script>';
					put 'function hint() {
				    			var x = document.getElementById("hint");
				  				if (x.style.display === "none") {
				  					x.style.display = "block";
				  				} else {
				    				x.style.display = "none";
				  				}
							}';
					put 'document.addEventListener("DOMContentLoaded", function(event) { hint();});';
					put '</script>';
					put '</head>';
					put '<body>';
				end;

				if first.id then
					do;
						/* Create the form calling the SAS JobExecution and the specific job */
						put '<form action="/SASJobExecution/">';
						put '<input type="hidden" name="_program" value="/gelcontent/Jobs/Quiz">';
						put '<input type="hidden" name="id" value="' id +(-1)'">';
						put '<section>';
						put '<header>';
						put '<h3>Q ' id "/&maxid : " questions '</h3>';
						put '</header>';
						put '<article>';
					end;
					
				put '<br>';
				put '<label> <input type="checkbox" name="' Name +(-1) '" value="' 
					Correct +(-1) '">' choices +(-1) '</label>';

				if last.id then
					do;
						put '<br><br>';
						put '<button type="button" onclick="hint();">Hint</button>';
						put '<input type="submit">';
						put '<div id="hint">' hint'</div>';
						put '</article>';
						put '</section>';
						put '</form>';
					end;
				if _n_=rows then do;
					put '</body>';
					put '</html>';
				end;
			run;

		%end;
%mend;

/*Macro generating the summary page */
%macro html_result;
	data _null_;
		length cssClass $200;
		set casuser.questions nobs=rows;
		file _webout;
		by id;
		/* Generate the HTML head */
		if _n_=1 then
			do;
				put '<html lang="en">';
				put '<head>';
				put '<title>quiz Programming</title>';
				put '<meta charset="utf-8">';
				put 
					'<meta name="viewport" content="width=device-width, initial-scale=1.0">';
				put '<meta author="BIZOUX, Xavier">';
				put '<style>';
				put 'article {padding-left:20px;}';
				put '.valid {display:block; background-color: lightgreen; width:400px;}';
				put '.invalid {display:block; background-color: red; width:400px;}';
				put '</style>';
				put '</head>';
				put '<body>';
			end;
		/* Generate the card for each question */
		if first.id then
			do;
				put '<section>';
				put '<header>';
				put '<h3>Q ' id "/&maxid : " questions '</h3>';
				put '</header>';
				put '<article>';
			end;

		if correct=1 then
			cssClass=' class="valid" ';
		else
			cssClass=' class="invalid" ';
		put '<label ' cssClass '>';
		put;

		if selected=1 then
			do;
				put '<input type="checkbox" checked disabled>';
			end;
		else
			do;
				put '<input type="checkbox" disabled>';
			end;
		put choices +(-1) '</label>';

		if last.id then
			do;
				put '</article>';
				put '<br>';
				put '<article>';
				put '<header> <h4>Answer</h4> </header>';
				put '<p>' justification '</p>';
				put '</article>';
				put '<br>';
				put '</section>';
			end;

		if _n_=rows then do;
			put '</body>';
			put '</html>';
		end;
	run;

%mend;
/* Call the different macros */
%init;
%html;
%finish;
