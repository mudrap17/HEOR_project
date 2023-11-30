libname sasfile '/home/u63633807/sasuser.v94/project_xpt';
libname projfile '/home/u63633807/sasuser.v94/project';
libname analysis '/home/u63633807/sasuser.v94/analysis_ds';

proc sort data=sasfile.cohort;
    by patient_id;
run;

proc sort data=projfile.encounter;
    by patient_id;
run;

data HRU_1;
    merge sasfile.cohort(in=a) projfile.encounter;
    by patient_id;
    if a;
run;

data HRU_2;
    set HRU_1;
    where '01Jan2017'd <= datepart(encounter_start_date) <= '30Nov2022'd;
    keep patient_id encounter_type cohort cohortn cohort1n;
run;

proc compare base=HRU_2 compare=analysis.hru;
run;
