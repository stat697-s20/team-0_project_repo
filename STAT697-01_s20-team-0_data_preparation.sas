*******************************************************************************;
**************** 80-character banner for column width reference ***************;
* (set window width to banner width to calibrate line length to 80 characters *;
*******************************************************************************;

/* 
[Dataset 1 Name] frpm1415

[Dataset Description] Student Poverty Free or Reduced Price Meals (FRPM) Data,
AY2014-15

[Experimental Unit Description] California public K-12 schools in AY2014-15

[Number of Observations] 10,393      

[Number of Features] 28

[Data Source] The file http://www.cde.ca.gov/ds/sd/sd/documents/frpm1415.xls
was downloaded and edited to produce file frpm1415-edited.xls by deleting
worksheet "Title Page", deleting row 1 from worksheet "FRPM School-Level Data",
reformatting column headers in "FRPM School-Level Data" to remove characters
disallowed in SAS variable names, and setting all cell values to "Text" format

[Data Dictionary] http://www.cde.ca.gov/ds/sd/sd/fsspfrpm.asp

[Unique ID Schema] The columns "County Code", "District Code", and "School
Code" form a composite key, which together are equivalent to the unique id
column CDS_CODE in dataset gradaf15, and which together are also equivalent to
the unique id column CDS in dataset sat15.
*/
%let inputDataset1DSN = frpm1415_raw;
%let inputDataset1URL =
https://github.com/stat697/team-0_project_repo/blob/master/data/frpm1415-edited.xls?raw=true
;
%let inputDataset1Type = XLS;


/*
[Dataset 2 Name] frpm1516

[Dataset Description] Student Poverty Free or Reduced Price Meals (FRPM) Data,
AY2015-16

[Experimental Unit Description] California public K-12 schools in AY2015-16

[Number of Observations] 10,453     

[Number of Features] 28

[Data Source] The file http://www.cde.ca.gov/ds/sd/sd/documents/frpm1516.xls
was downloaded and edited to produce file frpm1516-edited.xls by deleting
worksheet "Title Page", deleting row 1 from worksheet "FRPM School-Level Data",
reformatting column headers in "FRPM School-Level Data" to remove characters
disallowed in SAS variable names, and setting all cell values to "Text" format

[Data Dictionary] http://www.cde.ca.gov/ds/sd/sd/fsspfrpm.asp

[Unique ID Schema] The columns "County Code", "District Code", and "School
Code" form a composite key, which together are equivalent to the unique id
column CDS_CODE in dataset gradaf15, and which together are also equivalent to
the unique id column CDS in dataset sat15.
*/
%let inputDataset2DSN = frpm1516_raw;
%let inputDataset2URL =
https://github.com/stat697/team-0_project_repo/blob/master/data/frpm1516-edited.xls?raw=true
;
%let inputDataset2Type = XLS;


/*
[Dataset 3 Name] gradaf15

[Dataset Description] Graduates Meeting UC/CSU Entrance Requirements, AY2014-15

[Experimental Unit Description] California public K-12 schools in AY2014-15

[Number of Observations] 2,490

[Number of Features] 15

[Data Source] The file
http://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2014-15&cCat=UCGradEth&cPage=filesgradaf.asp
was downloaded and edited to produce file gradaf15.xls by importing into Excel
and setting all cell values to "Text" format

[Data Dictionary] http://www.cde.ca.gov/ds/sd/sd/fsgradaf09.asp

[Unique ID Schema] The column CDS_CODE is a unique id.
*/
%let inputDataset3DSN = gradaf15_raw;
%let inputDataset3URL =
https://github.com/stat697/team-0_project_repo/blob/master/data/gradaf15.xls?raw=true
;
%let inputDataset3Type = XLS;


/*
[Dataset 4 Name] sat15

[Dataset Description] SAT Test Results, AY2014-15

[Experimental Unit Description] California public K-12 schools in AY2014-15

[Number of Observations] 2,331

[Number of Features] 12

[Data Source]  The file http://www3.cde.ca.gov/researchfiles/satactap/sat15.xls
was downloaded and edited to produce file sat15-edited.xls by opening in Excel
and setting all cell values to "Text" format

[Data Dictionary] http://www.cde.ca.gov/ds/sp/ai/reclayoutsat.asp

[Unique ID Schema] The column CDS is a unique id.
*/
%let inputDataset4DSN = sat15_raw;
%let inputDataset4URL =
https://github.com/stat697/team-0_project_repo/blob/master/data/sat15-edited.xls?raw=true
;
%let inputDataset4Type = XLS;


/* load raw datasets over the wire, if they doesn't already exist */
%macro loadDataIfNotAlreadyAvailable(dsn,url,filetype);
    %put &=dsn;
    %put &=url;
    %put &=filetype;
    %if
        %sysfunc(exist(&dsn.)) = 0
    %then
        %do;
            %put Loading dataset &dsn. over the wire now...;
            filename
                tempfile
                "%sysfunc(getoption(work))/tempfile.&filetype."
            ;
            proc http
                    method="get"
                    url="&url."
                    out=tempfile
                ;
            run;
            proc import
                    file=tempfile
                    out=&dsn.
                    dbms=&filetype.
                ;
            run;
            filename tempfile clear;
        %end;
    %else
        %do;
            %put Dataset &dsn. already exists. Please delete and try again.;
        %end;
%mend;
%macro loadDatasets;
    %do i = 1 %to 4;
        %loadDataIfNotAlreadyAvailable(
            &&inputDataset&i.DSN.,
            &&inputDataset&i.URL.,
            &&inputDataset&i.Type.
        )
    %end;
%mend;
%loadDatasets


/* check frpm1415_raw for bad unique id values, where the columns County_Code,
District_Code, and School_Code are intended to form a composite key */
proc sql;
    /* check for duplicate unique id values; after executing this query, we
       see that frpm1415_raw_dups only has one row, which just happens to 
       have all three elements of the componsite key missing, which we can
       mitigate as part of eliminating rows having missing unique id component
       in the next query */
    create table frpm1415_raw_dups as
        select
             County_Code
            ,District_Code
            ,School_Code
            ,count(*) as row_count_for_unique_id_value
        from
            frpm1415_raw
        group by
             County_Code
            ,District_Code
            ,School_Code
        having
            row_count_for_unique_id_value > 1
    ;
    /* remove rows with missing unique id components, or with unique ids that
       do not correspond to schools; after executing this query, the new
       dataset frpm1415 will have no duplicate/repeated unique id values,
       and all unique id values will correspond to our experimenal units of
       interest, which are California Public K-12 schools; this means the 
       columns County_Code, District_Code, and School_Code in frpm1415 are 
       guaranteed to form a composite key */
    create table frpm1415 as
        select
            *
        from
            frpm1415_raw
        where
            /* remove rows with missing unique id value components */
            not(missing(County_Code))
            and
            not(missing(District_Code))
            and
            not(missing(School_Code))
            and
            /* remove rows for District Offices and non-public schools */
            School_Code not in ("0000000","0000001")
    ;
quit;


/* check frpm1516_raw for bad unique id values, where the columns County_Code,
District_Code, and School_Code form a composite key */
proc sql;
    /* check for duplicate unique id values; after executing this query, we
       see that frpm1516_raw_dups contains now rows, so no mitigation is
       needed to ensure uniqueness */
    create table frpm1516_raw_dups as
        select
             County_Code
            ,District_Code
            ,School_Code
            ,count(*) as row_count_for_unique_id_value
        from
            frpm1516_raw
        group by
             County_Code
            ,District_Code
            ,School_Code
        having
            row_count_for_unique_id_value > 1
    ;
    /* remove rows with missing unique id components, or with unique ids that
       do not correspond to schools; after executing this query, the new
       dataset frpm1516 will have no duplicate/repeated unique id values,
       and all unique id values will correspond to our experimenal units of
       interest, which are California Public K-12 schools; this means the 
       columns County_Code, District_Code, and School_Code in frpm1516 are 
       guaranteed to form a composite key */
    create table frpm1516 as
        select
            *
        from
            frpm1516_raw
        where
            /* remove rows with missing unique id value components */
            not(missing(County_Code))
            and
            not(missing(District_Code))
            and
            not(missing(School_Code))
            and
            /* remove rows for District Offices and non-public schools */
            School_Code not in ("0000000","0000001")
    ;
quit;


/* check gradaf15_raw for bad unique id values, where the column CDS_CODE is 
intended to be a primary key */
proc sql;
    /* check for unique id values that are repeated, missing, or correspond to
       non-schools; after executing this query, we see that
       gradaf15_raw_bad_unique_ids only has non-school values of CDS_Code that
       need to be removed */
    create table gradaf15_raw_bad_unique_ids as
        select
            A.*
        from
            gradaf15_raw as A
            left join
            (
                select
                     CDS_CODE
                    ,count(*) as row_count_for_unique_id_value
                from
                    gradaf15_raw
                group by
                    CDS_CODE
            ) as B
            on A.CDS_CODE=B.CDS_CODE
        having
            /* capture rows corresponding to repeated primary key values */
            row_count_for_unique_id_value > 1
            or
            /* capture rows corresponding to missing primary key values */
            missing(CDS_CODE)
            or
            /* capture rows corresponding to non-school primary key values */
            substr(CDS_CODE,8,7) in ("0000000","0000001")
    ;
    /* remove rows with primary keys that do not correspond to schools; after
       executing this query, the new dataset gradaf15 will have no
       duplicate/repeated unique id values, and all unique id values will
       correspond to our experimenal units of interest, which are California
       Public K-12 schools; this means the column CDS_Code in gradaf15 is 
       guaranteed to form a primary key */
    create table gradaf15 as
        select
            *
        from
            gradaf15_raw
        where
            /* remove rows for District Offices and non-public schools */
            substr(CDS_CODE,8,7) not in ("0000000","0000001")
    ;
quit;


/* check sat15_raw for bad unique id values, where the column CDS is intended
to be a primary key */
proc sql;
    /* check for unique id values that are repeated, missing, or correspond to
       non-schools; after executing this query, we see that
       sat15_raw_bad_unique_ids only has non-school values of CDS that need to
       be removed */
    create table sat15_raw_bad_unique_ids as
        select
            A.*
        from
            sat15_raw as A
            left join
            (
                select
                     CDS
                    ,count(*) as row_count_for_unique_id_value
                from
                    sat15_raw
                group by
                    CDS
            ) as B
            on A.CDS=B.CDS
        having
            /* capture rows corresponding to repeated primary key values */
            row_count_for_unique_id_value > 1
            or
            /* capture rows corresponding to missing primary key values */
            missing(CDS)
            or
            /* capture rows corresponding to non-school primary key values */
            substr(CDS,8,7) in ("0000000","0000001")
    ;
    /* remove rows with primary keys that do not correspond to schools; after
       executing this query, the new dataset gradaf15 will have no
       duplicate/repeated unique id values, and all unique id values will
       correspond to our experimenal units of interest, which are California
       Public K-12 schools; this means the column CDS in sat15 is guaranteed
       to form a primary key */
    create table sat15 as
        select
            *
        from
            sat15_raw
        where
           /* remove rows for District Offices */
           substr(CDS,8,7) ne "0000000"
    ;
quit;


/* build analytic dataset from raw datasets imported above, including only the
columns and minimal data-cleaning/transformation needed to address each
research questions/objectives in data-analysis files */
proc sql;
    create table cde_analytic_file_raw as
        select
             coalesce(A.CDS_Code,B.CDS_Code,C.CDS_Code,D.CDS_Code)
             AS CDS_Code
            ,coalesce(A.School,B.School,C.School,D.School)
             AS School
            ,coalesce(A.District,B.District,C.District,D.District)
             AS District
            ,A.Percent_Eligible_FRPM_K12_1415 format percent12.2
             label "FRPM Eligibility Rate in AY2014-15"
            ,B.Percent_Eligible_FRPM_K12_1516 format percent12.2
             label "FRPM Eligibility Rate in AY2015-16"
            ,B.Percent_Eligible_FRPM_K12_1516
             - A.Percent_Eligible_FRPM_K12_1415
             AS FRPM_Percentage_Point_Increase format percent12.2
             label "FRPM Eligibility Rate Percentage Point Increase"
            ,C.Number_of_Course_Completers format comma12.
             label "Number of 'a-g' Course Completers in AY2014-15"
            ,D.Number_of_SAT_Takers format comma12.
             label "Number of SAT Takers in AY2014-15"
            ,D.Number_of_SAT_Takers - C.Number_of_Course_Completers
             AS Course_Completers_Gap_Count format comma12.
             label "Gap Count between SAT Takers and 'a-g' Completers"
            ,calculated Course_Completers_Gap_Count
             / C.Number_of_Course_Completers format percent12.2
             label "Gap Percent between SAT Takers and 'a-g' Completers"
             AS Course_Completers_Gap_Percent
            ,D.Percent_with_SAT_above_1500 format percent12.2
             label "Percentage of SAT Takers Scoring 1500+ in AY2014-15"
        from
            (
                select
                     cats(County_Code,District_Code,School_Code)
                     AS CDS_Code
                     length 14
                    ,School_Name
                     AS
                     School
                    ,District_Name
                     AS
                     District
                    ,Percent_Eligible_FRPM_K12
                     AS Percent_Eligible_FRPM_K12_1415
                from
                    frpm1415
            ) as A
            full join
            (
                select
                     cats(County_Code,District_Code,School_Code)
                     AS CDS_Code
                     length 14
                    ,School_Name
                     AS
                     School
                    ,District_Name
                     AS
                     District
                    ,Percent_Eligible_FRPM_K12
                     AS Percent_Eligible_FRPM_K12_1516
                from
                    frpm1516
            ) as B
            on A.CDS_Code = B.CDS_Code
            full join
            (
                select
                     CDS_CODE
                     AS CDS_Code
                    ,SCHOOL
                     AS School
                    ,DISTRICT
                     AS
                     District
                    ,input(TOTAL,best12.)
                     AS Number_of_Course_Completers
                from
                    gradaf15
            ) as C
            on A.CDS_Code = C.CDS_Code
            full join
            (
                select
                     cds
                     AS CDS_Code
                    ,sname
                     AS School
                    ,dname
                     AS
                     District
                    ,input(NUMTSTTAKR,best12.)
                     AS Number_of_SAT_Takers
                    ,input(PCTGE1500, best12.)/100
                     AS Percent_with_SAT_above_1500
                from
                    sat15
            ) as D
            on A.CDS_Code = D.CDS_Code
        order by
            CDS_Code
    ;
quit;


/* check cde_analytic_file_raw for rows whose unique id values are repeated,
missing, or correspond to non-schools, where the column CDS_Code is intended
to be a primary key; after executing this data step, we see that the full joins
used above introduced duplicates in cde_analytic_file_raw, which need to be
mitigated before proceeding */
data cde_analytic_file_raw_bad_ids;
    set cde_analytic_file_raw;
    by CDS_Code;

    if
        first.CDS_Code*last.CDS_Code = 0
        or
        missing(CDS_Code)
        or
        substr(CDS_Code,8,7) in ("0000000","0000001")
    then
        do;
            output;
        end;
run;


/* remove duplicates from cde_analytic_file_raw with respect to CDS_Code;
after inspecting the rows in cde_analytic_file_raw_bad_ids, we saw that either
of the rows in duplicate-row pairs can be removed without losing values for
analysis, so we use proc sort to indiscriminately remove duplicates, after
which column CDS_Code is guaranteed to form a primary key */
proc sort
        nodupkey
        data=cde_analytic_file_raw
        out=cde_analytic_file
    ;
    by
        CDS_Code
    ;
run;
