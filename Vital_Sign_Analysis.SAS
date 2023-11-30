/* VS */

proc sql;
    create table vs1 as
    select 
        a.*, 
        b.index_date, 
        b.cohort, 
        b.cohortn, 
        b.cohort1n,
        b.death_date
    from 
        sasfile.vital_sign a
        left join cohort_3 b 
        on a.patient_id = b.patient_id
    /* Cohort Selection */
    where 
        a.patient_id in (select patient_id from cohort_3) AND
        /*Select records After Index Date-30 Days */
        .z < index_date - 30 < vital_date AND
        loinc in ('8462-4', '8480-6', '8867-4')
    order by patient_id, loinc, vital_date;
quit;

proc sql;
    create table vs2_base as
    select 
        a.patient_id, 
        a.loinc, 
        a.cohort1n, 
        a.value, 
        a.vital_date, 
        a.death_date
    from 
        vs1 a
    where
        /*Select records After Index Date-30 Days */
        .z < index_date - 30 < vital_date < index_date + 30 AND
        /*loinc in ("&Loinc.") AND */
        not missing(value)
    order by patient_id, loinc, vital_date;
quit;

/* Select records After Index Date-30 Days */
Data vs2_base1;
    set vs2_base;
    by patient_id loinc vital_date;
    if last.loinc ;
    Rename Value=Base;
run;

/* Post-Baseline */
/* Select Post-Baseline >
   - Last available non-missing record after Index Date AND
   - Before Death Date (if any death date)
   - Will consider them as Baseline Value */

proc sql;
    create table vs2_Post as
    select 
        a.patient_id, 
        a.loinc, 
        a.cohort1n, 
        a.value, 
        a.vital_date
    from 
        vs1 a
    where
        /*Select records After Index Date Days*/
        .z < index_date < vital_date AND
        /*loinc in ("&Loinc.") AND */
        not missing(value)
    order by patient_id, loinc, vital_date;
quit;

/* Select records After Index Date-30 Days */
Data vs2_Postl;
    set vs2_Post;
    by patient_id loinc vital_date;
    /* Delete Records if any AFTER Death Date */
    if death_date ne . and vital_date > death_date > .z then delete;
    if last.loinc ; /* Select Latest Record */
    Rename Value=Post_Base;
run;

data Vital_Sign_Analysis_m;
    merge vs2_base1 (in=a)
          vs2_Postl (in=b);
    by patient_id loinc ;
    CHG = Post_base - base;
run;

proc compare base=analysis.vital_sign_analysis compare=vital_sign_analysis_m;
