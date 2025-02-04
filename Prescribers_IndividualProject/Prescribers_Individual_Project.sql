--Prescribers-Individual Project

--1.a.Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT prescriber.npi, nppes_provider_last_org_name, SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi
WHERE total_claim_count IS NOT NULL
GROUP BY prescriber.npi, nppes_provider_last_org_name, prescription.total_claim_count
ORDER BY total_claims DESC
LIMIT 1;

--//Coffey had the highest number of total claims, 4,538.

--1.b.Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi
WHERE total_claim_count IS NOT NULL
GROUP BY nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY total_claims DESC
LIMIT 1;

--//Bruce Pendley had the highest number of claims, 99,707.

--2.a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi
WHERE total_claim_count IS NOT NULL
GROUP BY specialty_description
ORDER BY total_claims DESC;

--//Family Practice had the most total number of claims.

--2.b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description, SUM(total_claim_count) AS total_claims, drug.drug_name, opioid_drug_flag
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi
LEFT JOIN drug
ON prescription.drug_name = drug.drug_name
WHERE total_claim_count IS NOT NULL
AND opioid_drug_flag = 'Y'
GROUP BY specialty_description, drug.drug_name, opioid_drug_flag
ORDER BY total_claims DESC;

--//Nurse Practitioner had the most total number of claims for opioids.

--2.c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT DISTINCT specialty_description
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi
WHERE prescription.npi IS NULL;

--//There are 92 specialties that appear in the prescriber table that have no associated prescriptions in the prescription table.

--2.d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

WITH opioids AS (
	SELECT drug_name
	FROM drug
	WHERE opioid_drug_flag = 'Y'
	)
SELECT specialty_description,
	ROUND((COUNT(opioids.drug_name)/SUM(total_claim_count)*100), 2) AS opioid_percent
FROM prescriber
JOIN prescription
USING (npi)
JOIN opioids
USING (drug_name)
GROUP BY specialty_description
ORDER BY opioid_percent DESC;

--//General Acute Care Hospital and Critical Care both had 9.09%.

--3a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name, SUM(total_drug_cost) AS total_cost
FROM prescription
LEFT JOIN drug
ON prescription.drug_name = drug.drug_name
WHERE total_drug_cost IS NOT NULL
GROUP BY generic_name
ORDER BY total_cost DESC
LIMIT 1;

--//Insulin Glargine,Hum.Rec.Anlog with 104264066.35 had the highest total drug cost.


--3b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

SELECT generic_name, ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2) AS cost_per_day
FROM prescription
LEFT JOIN drug
ON prescription.drug_name = drug.drug_name
WHERE total_drug_cost IS NOT NULL
GROUP BY generic_name
ORDER by cost_per_day DESC
LIMIT 1;

--//C1 Esterase Inhibitor was ranked the highest and had a cost of 3,495.22 per day.

--4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT DISTINCT drug_name,
CASE 
    WHEN opioid_drug_flag = 'Y' THEN 'opioid' 
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither'
END AS drug_type
FROM drug
ORDER BY drug_type;

--//There are 3,260 rows and Amikacin Sulfate is an antibiotic listed at the top.


--4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT DISTINCT drug.drug_name, SUM(total_drug_cost) AS total_cost,
CASE 
    WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid' 
	WHEN drug.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither'
END AS drug_type
FROM prescription
LEFT JOIN drug
ON prescription.drug_name = drug.drug_name
GROUP BY drug.drug_name, drug.opioid_drug_flag, drug.antibiotic_drug_flag
ORDER BY total_cost DESC;


--**********STILL WORKING ON SEPARATING ANTIBIOTICS AND OPIOIDS. Use a CTE to compare and contrast totals.

--5a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(DISTINCT cbsa)
FROM cbsa
WHERE cbsaname ILIKE '%TN%';

--//There are 11 cbsa's in TN.

--5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsa.cbsaname, SUM(population.population) AS total_population
FROM cbsa
LEFT JOIN fips_county
ON cbsa.fipscounty = fips_county.fipscounty
LEFT JOIN population
ON fips_county.fipscounty = population.fipscounty
GROUP BY cbsa.cbsaname
HAVING SUM(population.population) IS NOT NULL
ORDER BY total_population DESC
LIMIT 1;

--//Nashville-Davidson-Murfreesboro-Franklin, TN with population 1,830,410 as the largest.

SELECT cbsa.cbsaname, SUM(population.population) AS total_population
FROM cbsa
LEFT JOIN fips_county
ON cbsa.fipscounty = fips_county.fipscounty
LEFT JOIN population
ON fips_county.fipscounty = population.fipscounty
GROUP BY cbsa.cbsaname
HAVING SUM(population.population) IS NOT NULL
ORDER BY total_population ASC
LIMIT 1;

--//Morristown, TN has the smallest population, 116,352.

--5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.


SELECT DISTINCT fips_county.county AS county, SUM(population.population) AS largest_pop
FROM fips_county
LEFT JOIN population
ON fips_county.fipscounty = population.fipscounty
LEFT JOIN cbsa
ON fips_county.fipscounty = cbsa.fipscounty
GROUP BY county
HAVING SUM(population.population) IS NOT NULL
ORDER BY largest_pop DESC;

--//Shelby is the largest county which has 937,847.

--6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT DISTINCT drug_name, SUM(total_claim_count) AS total_claims
FROM prescription
WHERE total_claim_count >= 3000
GROUP BY drug_name
ORDER BY total_claims DESC;

--//There are 7 rows given. Levothyroxine Sodium appears at the top with 9,262.

--6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

WITH opioid_drug_flag AS (    
   SELECT DISTINCT drug.drug_name,     SUM(total_claim_count) AS total_claims, drug.opioid_drug_flag, CONCAT(prescriber.nppes_provider_last_org_name, prescriber.nppes_provider_first_name) AS provider_full_name
FROM prescription
LEFT JOIN drug
ON prescription.drug_name = drug.drug_name
LEFT JOIN prescriber
ON prescription.npi = prescriber.npi
WHERE total_claim_count >= 3000 
GROUP BY drug.drug_name, drug.opioid_drug_flag, provider_full_name
ORDER BY total_claims DESC
)
SELECT *
FROM opioid_drug_flag;

--//There are two results that are flagged as opioids. Oxycodone HCL and Hydrocodone-Acetaminophen.

--6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

--//Provider full name provided with David Coffey listed at the top.

--7.The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

--7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.


SELECT npi, drug_name
FROM drug
CROSS JOIN prescriber
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';

--//There are 637 rows for part a.

--7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

WITH prescription_join AS(
    SELECT npi, drug_name
	FROM drug
	CROSS JOIN prescriber
	WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
	)
SELECT prescription_join.npi,
prescription_join.drug_name,
    COALESCE(total_claim_count, '0') AS total_claims
FROM prescription_join
LEFT JOIN prescription
USING(npi, drug_name);   

--//There are 637 rows

