* OS;

libname analysis '/home/u63633807/sasuser.v94/analysis_ds';

Proc sql;
    create table OS1 as
    select a.patient_id, max(last_date) as Last_Followup
    from 
    (
        (select patient_id, condition_date as last_date from projfile.condition where patient_id in (select patient_id from cohort_1))
        outer union corr 
        (select patient_id, datepart(result_date) as last_date from sasfile.lab where patient_id in (select patient_id from cohort_1))
        outer union corr 
        (select patient_id, request_date as last_date from projfile.medication where patient_id in (select patient_id from cohort_1))
        outer union corr 
        (select patient_id, datepart(procedure_date) as last_date from sasfile.procedure where patient_id in (select patient_id from cohort_1))
        outer union corr 
        (select patient_id, datepart(encounter_start_date) as last_date from sasfile.encounter where patient_id in (select patient_id from cohort_1))
        outer union corr 
        (select patient_id, datepart(encounter_end_date) as last_date from sasfile.encounter where patient_id in (select patient_id from cohort_1))
        outer union corr 
        (select patient_id, datepart(vital_date) as last_date from sasfile.vital_sign where patient_id in (select patient_id from cohort_1))
        outer union corr 
        (select patient_id, datepart(birth_date) as last_date from sasfile.patient where patient_id in (select patient_id from cohort_1))
    ) as a 
    where patient_id ne "" 
    group by patient_id 
    order by patient_id;
quit;

data OS;
    merge OS1 (in=a) cohort_3 (in=b);
    by patient_id;
    if a;
    start_date=Index_Date;
    If death_date ne . then do;
        CNSR=0; Event=1; ADT=death_date; EVNTDESC="Death"; 
    end;
    Else If death_date eq . and last_followup ne . then do;
        CNSR=1; Event=0; ADT=last_followup; EVNTDESC="No Event: Censored at Last Activity Date"; 
    end;
    Else If death_date eq . and last_followup eq . then do;
        put "Alert: Check the records" Patient_id=Death_date=last_followup =;
        CNSR=1; Event=0; ADT=index_date; EVNTDESC="No Event: Censored at Index Date";
    end;
    if start_date > death_date > .z then do;
        start_date=death_date;
        remove_records=1;
    end;
    if start_date > adt > .z then do;
        start_date=adt;
        remove_records=1;
    end;
    if remove_records=1 then
        put "Alert: Check the records" Patient_id=Death_date=last_followup =;
    AVAL=(ADT - start_date + 1) / (365/12);
    keep patient_id AVAL CNSR EVNTDESC adt start_date cohort cohortN last_followup;
run;

proc compare base=analysis.os compare=os;

