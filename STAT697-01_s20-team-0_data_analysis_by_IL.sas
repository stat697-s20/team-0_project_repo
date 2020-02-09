*******************************************************************************;
**************** 80-character banner for column width reference ***************;
* (set window width to banner width to calibrate line length to 80 characters *;
*******************************************************************************;

/* load external file generating "analytic file" dataset cde_analytic_file,
from which all data analyses below begin */
%include './STAT697-01_s20-team-0_data_preparation.sas';


*******************************************************************************;
* Research Question 1 Analysis Starting Point;
*******************************************************************************;
/*
Question 1 of 3: What are the top five schools that experienced the biggest
increase in "Percent (%) Eligible Free (K-12)" between AY2014-15 and AY2015-16?

Rationale: This should help identify schools to consider for new outreach based
upon increasing child-poverty levels.

Note: This compares the column "Percent (%) Eligible Free (K-12)" from frpm1415
to the column of the same name from frpm1516.

Limitations: Values of "Percent (%) Eligible Free (K-12)" equal to zero should
be excluded from this analysis, since they are potentially missing data values
*/


proc sql outobs=5;
    select
         School
        ,District
        ,Percent_Eligible_FRPM_K12_1415
        ,Percent_Eligible_FRPM_K12_1516
        ,FRPM_Percentage_Point_Increase
    from
        cde_analytic_file
    where
        Percent_Eligible_FRPM_K12_1415 > 0
        and
        Percent_Eligible_FRPM_K12_1516 > 0
    order by
        FRPM_Percentage_Point_Increase desc
    ;
quit;


*******************************************************************************;
* Research Question 2 Analysis Starting Point;
*******************************************************************************;
/*
Question 2 of 3: Can "Percent (%) Eligible FRPM (K-12)" be used to predict the
proportion of high school graduates earning a combined score of at least 1500
on the SAT?

Rationale: This would help inform whether child-poverty levels are associated
with college-preparedness rates, providing a strong indicator for the types of
schools most in need of college-preparation outreach.

Note: This compares the column "Percent (%) Eligible Free (K-12)" from frpm1415
to the column PCTGE1500 from sat15.

Limitations: Values of "Percent (%) Eligible Free (K-12)" equal to zero should
be excluded from this analysis, since they are potentially missing data values,
and missing values of PCTGE1500 should also be excluded
*/


proc rank
        groups=10
        data=cde_analytic_file
        out=cde_analytic_file_ranked
    ;
    var Percent_Eligible_FRPM_K12_1415;
    ranks Percent_Eligible_FRPM_K12_rank;
run;
proc rank
        groups=10
        data=cde_analytic_file_ranked
        out=cde_analytic_file_ranked
    ;
    var Percent_with_SAT_above_1500;
    ranks Percent_with_SAT_above_1500_rank;
run;

proc freq data=cde_analytic_file_ranked;
    table
          Percent_Eligible_FRPM_K12_rank
        * Percent_with_SAT_above_1500_rank
        / norow nocol nopercent
    ;
    label
        Percent_Eligible_FRPM_K12_rank=" "
        Percent_with_SAT_above_1500_rank=" "
    ;
    where
        not(missing(Percent_Eligible_FRPM_K12_1415))
        and
        not(missing(Percent_with_SAT_above_1500))
    ;
run;


*******************************************************************************;
* Research Question 3 Analysis Starting Point;
*******************************************************************************;
/*
Question 3 of 3: What are the top ten schools were the number of high school graduates
taking the SAT exceeds the number of high school graduates completing UC/CSU
entrance requirements?

Rationale: This would help identify schools with significant gaps in
preparation specific for California's two public university systems, suggesting
where focused outreach on UC/CSU college-preparation might have the greatest
impact.

Note: This compares the column NUMTSTTAKR from sat15 to the column TOTAL from
gradaf15.

Limitations: Values of NUMTSTTAKR and TOTAL equal to zero should be excluded
from this analysis, since they are potentially missing data values
*/


proc sql outobs=10;
    select
         School
        ,District
        ,Number_of_SAT_Takers /* NUMTSTTAKR from sat15 */
        ,Number_of_Course_Completers /* TOTAL from gradaf15 */
        ,Course_Completers_Gap_Count
        ,Course_Completers_Gap_Percent format percent12.1
    from
        cde_analytic_file
    where
        Number_of_SAT_Takers > 0
        and
        Number_of_Course_Completers > 0
    order by
        Course_Completers_Gap_Count desc
    ;
quit;
