libname sasfile '/home/u63633807/sasuser.v94/project_xpt'; /* location of new files created */
libname projfile '/home/u63633807/sasuser.v94/project'; /*location of the correct files */
proc sort data = sasfile.patient;
by patient_id;
run;
proc sort data = sasfile.medication;
by patient_id;
run;
proc sort data = sasfile.condition;
by patient_id;
run;

data med2 replace;
set sasfile.medication;
length cohort $20.;
If ndc in (3089421 636297747) OR Index(upcase(medication_name), "APIXABAN") then do;
Cohort="NOAC"; CohortN=1; end;
else If ndc in ( 5970108) OR Index(upcase(medication_name), "DABIGATRAN") then do;
Cohort="NOAC"; CohortN=1; end;
else If ndc in ( 50458577) OR Index(upcase(medication_name), "RIVAROXABAN") then do;
Cohort="NOAC"; CohortN=1; end;
else If ndc in ( 31722327) OR Index(upcase(medication_name), "WARFARIN") then do;
Cohort="Warfarin"; CohortN=2; end;
else If ndc in (2802100) OR Index(upcase(medication_name), "ASPIRIN") then do;
Cohort="Aspirin"; CohortN=3; end;
age=intck('year', birth_date, Index_date);
run;

data med3(rename=(request_date=Index_date)) replace;
set med2;
where '01Jan2017'd <= request_date <= '01Jan2021'd and
Cohort ne ' ';
run;

proc sort data=med3 out=Med_Cohorts (keep=patient_id cohort: medication_name Index_date) nodupkey;
by patient_id cohort medication_name;
*where patient_id in ('238091');
run;
proc freq data=Med_Cohorts order=freq noprint;
table patient_id/list out=Multi_Cohort_ID (where=(count>1) );
run;

data cond2 replace;
set sasfile.condition;
where substr(Code, 1, 3) = 'I48' and
condition_date between '01Jan2007'd and '01Jan2019'd;
run;

proc sql;
create table Cohort_1 as select distinct a.patient_id, a.birth_date, propcase (a.gender) as
gender, a.death_date, a.death_flag, propcase (a.race) as race, b.cohort,
b.cohortN, case (b.cohortn) when 1 then 1 else 2 end as cohort1n,
(b.Index_date - a.birth_date +1) /365 as age, b.Index_date from sasfile.patient a inner
join /* We want Patients with AF and Treated with selective Drugs*/
Med_Cohorts b on a.patient_id=b.patient_id
/* Inclusion Criteria 1: Age > 18 */
where calculated age>=18 and
/* Inclusion Criteria 2: Condition of AF etc */
a.patient_id in (select distinct patient_id from cond2) AND
/* Inclusion Criteria 3: Taken specific medications etc */
a.patient_id in (select distinct patient_id from med3) AND
/* Exclusion Criteria 1: Fracture Exclusion
M81 - Age-related osteoporosis without current pathological fracture
197 - Postprocedural cardiac insufficiency
*/
a.patient_id not in (select distinct patient_id from sasfile.condition where substr(code, 1, 3) in ("M81","I97") ) AND
/* Exclusion Criteria 2: Fluoroscopy of Heart - Exclude
Codes: B215YZZ B2151ZZ B2151ZZ */
a.patient_id not in (select distinct patient_id from sasfile.procedure where code
in ("B215YZZ","B2151ZZ" ,"B2151ZZ") ) 
order by a.patient_id;
quit;

proc freq data=Cohort_1;
table cohort;

data medication;
set sasfile.medication;

data condition;
set sasfile.condition;

proc sql;
create table Cohort_2 as select a.* , c.chf , d.hyp, e.diab, f.STROK, g.vsc,
r.AbRenal, l.AbLiver, k.Bleed, al.alcoh, med1.nsaid , med4.antiplat,
med5.PPI, med6.h2anta, med7.AntiArr, med8.digi, med9.Statin, x.STROK_2 from Cohort_1 a 
left join
(select distinct patient_id, 1 as CHF from condition where substr (code, 1, 3)
in ("I50") ) c on a.patient_id=c.patient_id left join
(select distinct patient_id, 1 as HYP from condition where substr (code, 1, 3)
in ("I10" ,"I11" ,"I12", "I13", "I14" ,"I15") ) d on a.patient_id=d.patient_id
left join
(select distinct patient_id, 1 as DIAB from condition where substr (code, 1, 3)
in ("E10", "E11", "E12" ,"E13" ,"E14") ) e on a.patient_id=e.patient_id left
join
(select distinct patient_id, 1 as STROK from condition where substr (code, 1, 3)
in ("I63", "I693" ,"G459", "I69", "G45") ) f on a.patient_id=f.patient_id left join
(select distinct patient_id, 2 as STROK_2 from condition where substr (code, 1, 3)
in ("I63", "I693" "G459" ) ) x on a.patient_id=x.patient_id left join
(select distinct patient_id, 1 as VSC from condition where substr (code, 1, 3)
in ("I21", "I252" ,"I70", "I71" ,"I72" ,"I73") ) g on a.patient_id=g.patient_id
left join
(select distinct patient_id, 1 as AbRenal from condition where substr (code, 1,
3) in ("N183", "N184") ) r on a.patient_id=r.patient_id left join
(select distinct patient_id, 1 as AbLiver from condition where substr (code, 1,
3) in ("B15", "B16", "B17", "B18", "B19", "C22", "D684", "I982", "I983",
"K70","K71", "K72" , "K73", "K74","K75", "K76","K77", "Z944") ) l on a.patient_id=l.patient_id left join
(select distinct patient_id, 1 as Bleed from condition where code in ("I60", "I61", "I62", "I690", "I691", "I692", "S064", "S065", "S066", "S068",
 "I850", "I983", "K2211", "K226", "K228", "K250", "K252", "K254", "K256", "K260", "K262", "K264", "K266", "K270", "K272", "K274", "K276", "K280", "K282", "K284", "K286", "K290", "K3181", "K5521", "K625", 
 "K920", "K921", "K922", "D62", "H448", "H3572", "H356", "H313", "H210", "H113", "H052", 
 "H470", "H431", "1312", "N024", "N021", "N029", "N022", "N023", "N025", "N026", "N027", "N028", "N421", "N831", "N857", "N920", 
 "N923", "N930", "N938", "N939", "M250", "R233", "R040", "R041", 
 "R042", "R048", "R049", "T792", "T810", "N950", "R310", "R311", 
 "R318", "R58", "T455")) k on a.patient_id=k.patient_id 
 left join
(select distinct patient_id, 1 as Alcoh from condition where substr (code, 1, 3) in
("E244", "F10" ,"G312" ,"G621" ,"G721", "I426" ,"K292" ,"K70", "K860" ,"X65" ,"Y15", 'O354', 'P043', 'Q860', 'T510', 'X45',
"Y90","Y91" ,"Z502", "Z714","Z721") ) al on a.patient_id=al.patient_id left join
(select distinct patient_id, 1 as nsaid from Medication where PRXMATCH
("/Bromfenac | Celecoxib | Diclofenac | Etodolac | Fenoprofen | Flurbiprofen | Ibuprofen | Indomethacin | Keto
profen | Ketorolac | Naproxen | Meclofenamate | Mefenamic
acid | Meloxicam | Nabumetone | Oxaprozin | Piroxicam | Sulindac | Tolmetin/",
medication_name) ) med1 on a.patient_id=med1.patient_id left join
(select distinct patient_id, 1 as AntiPlat from Medication where PRXMATCH
("/Aspirin | Clopidogrel | Prasugrel | Ticlopidine | Cilostazol | Abciximab | Tirofiban | Dipyridamole | Ticag
relor/",medication_name) ) med4 on a.patient_id=med4.patient_id left join
(select distinct patient_id, 1 as PPI from Medication where PRXMATCH
("/Omeprazole | Pantoprazole | Lansoprazole | Rabeprazole | Esomeprazole | Dexlansoprazole|/",
medication_name) ) med5 on a.patient_id=med5.patient_id left join
(select distinct patient_id, 1 as H2Anta from Medication where PRXMATCH
("/Cimetidine | Ranitidine | Famotidine | Nizatidine | Roxatidine | Lafutidine/",
medication_name) ) med6 on a.patient_id=med6.patient_id left join
(select distinct patient_id, 1 as AntiArr from Medication where PRXMATCH
("/Quinidine | Procainamide | Mexiletine | Propafenone | Flecainide | Amiodarone | Bretylium | Dronedarone/",
medication_name) ) med7 on a.patient_id=med7.patient_id left join
(select distinct patient_id, 1 as Digi from Medication where
PRXMATCH ("/Digoxin/", medication_name) ) med8 on
a.patient_id=med8.patient_id left join
(select distinct patient_id, 1 as Statin from Medication where PRXMATCH
("/Atorvastatin | Fluvastatin | Lovastatin | Pitavastatin | Pravastatin | Roxuvastatin | Simvastatin/",
medication_name) ) med9 on a.patient_id=med9.patient_id order by patient_id;
quit;

data Cohort_3;
set Cohort_2;
Gender=propcase (gender) ;
****
*Table 9. CHA2DS2-VASc Score;
if upcase (gender) ="FEMALE" then do;
female=1;
end;

if 75=> age >=65 then do;
Age1=1;
Age2=1;
AgeCat="65=< to 75"; end;
else if age >75 then do;
Age1=2;
AgeCat="75<"; end;
else if .z < age <65 then do;
Age1=0;
AgeCat="<65";
end;
Year=year(Index_date);

CHA2DS2=sum(Agel, female, chf,hyp, diab, STROK_2, vsc);

if antiplat=1 or nsaid=1 then
drugtherapy=1;
HASBLED=sum (hyp, AbRenal, AbLiver , Bleed, (STROK_2 -1), alcoh, drugtherapy, age2);
run;

proc contents data=cohort_3;
run;

Data Cohort sasfile.cohort_m;
set cohort_3;
keep patient_id gender death_date death_flag race cohort CohortN cohort1n Index_date birth_date Age STROK Bleed AgeCat CHA2DS2 HASBLED Year;
run;

proc compare base=sasfile.cohort_m compare=sasfile.cohort;

*OS;

libname analysis '/home/u63633807/sasuser.v94/analysis_ds';
Proc sql;
create table OS1 as select a.patient_id, max(last_date) as Last_Followup
from 
((select patient_id, condition_date as last_date from projfile.condition where patient_id
in (select patient_id from cohort_1) ) outer union corr (select patient_id,
datepart (result_date) as last_date from sasfile.lab where patient_id in (select
patient_id from cohort_1)) outer union corr (select patient_id, request_date as
last_date from projfile.medication where patient_id in (select patient_id from
cohort_1)) outer union corr (select patient_id, datepart (procedure_date) as
last_date from sasfile.procedure where patient_id in (select patient_id from
cohort_1)) outer union corr (select patient_id, datepart (encounter_start_date)
as last_date from sasfile.encounter where patient_id in (select patient_id from
cohort_1)) outer union corr (select patient_id, datepart (encounter_end_date) as
last_date from sasfile.encounter where patient_id in (select patient_id from
cohort_1)) outer union corr (select patient_id, datepart (vital_date) as
last_date from sasfile.vital_sign where patient_id in (select patient_id from
cohort_1)) outer union corr (select patient_id, datepart (birth_date) as
last_date from sasfile.patient where patient_id in (select patient_id from cohort_1)
)) as a where patient_id ne "" group by patient_id order by patient_id;
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

if start_date> death_date >.z then do;
start_date=death_date;
remove_records=1;
end;
if start_date> adt >.z then do;
start_date=adt;
remove_records=1;
end;
if remove_records=1 then
put "Alert: Check the records" Patient_id=Death_date=last_followup =;

AVAL=(ADT - start_date + 1) / (365/12);
keep patient_id AVAL CNSR EVNTDESC adt start_date cohort cohortN last_followup;
run;

proc compare base=analysis.os compare=os;


/*TRT*/

proc sql;
create table Med_1 as select * from med2 as a where patient_id in
(select distinct patient_id from cohort_1);
quit;

data med_2;
set Med_1;
/* Index Date - Request_date is within range */
where '1Jan2017'd <= request_date <= '1Jan2021'd;
/* Select Medication cohorts */
length Category $40;
if PRXMATCH
("/Bromfenac | Celecoxib | Diclofenac |Etodolac | Fenoprofen | Flurbiprofen | Ibuprofen | Indomethacin | Keto
profen | Ketorolac | Naproxen | Meclofenamate | Mefenamic
acid | Meloxicam | Nabumetone | Oxaprozin | Piroxicam | Sulindac | Tolmetin/i",
medication_name) then
Category="NSAIDs";
else if PRXMATCH
("/Aspirin | Clopidogrel | Prasugrel | Ticlopidine | Cilostazol | Abciximab | Tirofiban | Dipyridamole | Ticag
relor/i",
medication_name) then
Category="Anti-Platelet";
else if PRXMATCH
("/Omeprazole | Pantoprazole |Lansoprazole | Rabeprazole | Esomeprazole |Dexlansoprazole/i",
medication_name) then
category="PPI";
else if PRXMATCH ("/Cimetidine| Ranitidine |Famotidine | Nizatidine | Roxatidine | Lafutidine/i",
medication_name) then
category="H2 Antagonist";
else if PRXMATCH
("/Quinidine | Procainamide |Mexiletine | Propafenone | Flecainide | Amiodarone | Bretylium | Dronedarone/i",
medication_name) then
category="Antiarrhythmics";
else if PRXMATCH ("/Digoxin/", medication_name) then
category="Digoxin";
else if PRXMATCH
("/Atorvastatin | Fluvastatin | Lovastatin | Pitavastatin | Pravastatin | Roxuvastatin | Simvastatin/i",
medication_name) then
category="Statins";
run;

proc sql;
create table trt_pattern as select distinct a.patient_id,
count (a.encounter_id) as Num_Presc, count (distinct category) as Num_Cat,
b.cohort, b.cohortn, b.cohortn from med_2 as
a /*Data is selected for timeframe: Index Date - Request_date is within range*/
inner join cohort_3 as b on a.patient_id=b.patient_id group by a.patient_id,
b.cohort, b.cohortn, b.cohort1n;
quit;

proc compare base=analysis.trt_pattern compare=trt_pattern; run;

/*VS*/


proc sql;
create table vs1 as
select a .* , b.index_date, b.cohort, b.cohortn, b.cohort1n ,b.death_date
from sasfile.vital_sign a
left join cohort_3 b
on a.patient_id = b.patient_id
/* Cohort Selection */
where a.patient_id in (select patient_id from cohort_3) AND
/*Select records After Index Date-30 Days */
.z <index_date-30 < vital_date AND
loinc in ('8462-4', '8480-6', '8867-4')
order by patient_id, loinc, vital_date;
quit;


proc sql;
create table vs2_base as
select a.patient_id, a.loinc, a.cohort1n , a.value, a.vital_date, a.death_date
from vs1 a
where
/*Select records After Index Date-30 Days */
.z <index_date-30 < vital_date <index_date+30 AND
/*loinc in ("&Loinc.") AND */
not missing (value)
order by patient_id, loinc, vital_date;
quit;

/*Select records After Index Date-30 Days */
Data vs2_base1;
set vs2_base;
by patient_id loinc vital_date;
if last.loinc ;
Rename Value=Base;
run;
*Post-Baseline;
/*Select Post-Baseline >
- Last available non-missing record after Index Date AND
- Before Death Date (if any death date)
- Will consider them as Baseline Value */

proc sql;
create table vs2_Post as
select a.patient_id, a.loinc, a.cohort1n , a.value, a.vital_date
from vs1 a
where
/*Select records After Index Date Days*/
.z <index_date < vital_date AND
/*loinc in ("&Loinc.") AND */
not missing (value)
order by patient_id, loinc, vital_date;
quit;


/*Select records After Index Date-30 Days */

Data vs2_Postl;
set vs2_Post;
by patient_id loinc vital_date;
** Delete Records if any AFTER Death Date **;
if death_date ne . and vital_date>death_date>.z then delete;
if last.loinc ; ** Select Latest Record;
Rename Value=Post_Base;
run;

data Vital_Sign_Analysis_m;
merge vs2_base1 (in=a)
vs2_Postl (in=b);
by patient_id loinc ;
CHG=Post_base-base;
run;

proc compare base=analysis.vital_sign_analysis compare=vital_sign_analysis_m;
