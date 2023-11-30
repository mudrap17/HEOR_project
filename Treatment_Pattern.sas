/* TRT */

proc sql;
    create table Med_1 as
    select * 
    from med2 as a 
    where patient_id in (select distinct patient_id from cohort_1);
quit;

data med_2;
    set Med_1;
    /* Index Date - Request_date is within range */
    where '1Jan2017'd <= request_date <= '1Jan2021'd;
    /* Select Medication cohorts */
    length Category $40;
    if PRXMATCH("/Bromfenac | Celecoxib | Diclofenac |Etodolac | Fenoprofen | Flurbiprofen | Ibuprofen | Indomethacin | Keto profen | Ketorolac | Naproxen | Meclofenamate | Mefenamic acid | Meloxicam | Nabumetone | Oxaprozin | Piroxicam | Sulindac | Tolmetin/i", medication_name) then
        Category="NSAIDs";
    else if PRXMATCH("/Aspirin | Clopidogrel | Prasugrel | Ticlopidine | Cilostazol | Abciximab | Tirofiban | Dipyridamole | Ticag relor/i", medication_name) then
        Category="Anti-Platelet";
    else if PRXMATCH("/Omeprazole | Pantoprazole |Lansoprazole | Rabeprazole | Esomeprazole |Dexlansoprazole/i", medication_name) then
        category="PPI";
    else if PRXMATCH("/Cimetidine| Ranitidine |Famotidine | Nizatidine | Roxatidine | Lafutidine/i", medication_name) then
        category="H2 Antagonist";
    else if PRXMATCH("/Quinidine | Procainamide |Mexiletine | Propafenone | Flecainide | Amiodarone | Bretylium | Dronedarone/i", medication_name) then
        category="Antiarrhythmics";
    else if PRXMATCH("/Digoxin/", medication_name) then
        category="Digoxin";
    else if PRXMATCH("/Atorvastatin | Fluvastatin | Lovastatin | Pitavastatin | Pravastatin | Roxuvastatin | Simvastatin/i", medication_name) then
        category="Statins";
run;

proc sql;
    create table trt_pattern as
    select distinct 
        a.patient_id,
        count(a.encounter_id) as Num_Presc,
        count(distinct category) as Num_Cat,
        b.cohort,
        b.cohortn,
        b.cohortn
    from 
        med_2 as a
        /*Data is selected for timeframe: Index Date - Request_date is within range*/
        inner join cohort_3 as b 
        on a.patient_id=b.patient_id 
    group by 
        a.patient_id,
        b.cohort,
        b.cohortn,
        b.cohort1n;
quit;

proc compare base=analysis.trt_pattern compare=trt_pattern; 
run;
