-- SQLite does not support DROP COLUMN directly, so we recreate the table without that column
-- Step 1: Rename the existing table
ALTER TABLE stressor_responses RENAME TO stressor_responses_old;

-- Step 2: Recreate the table without `stressor_category`
CREATE TABLE stressor_responses (
  main_id INTEGER PRIMARY KEY AUTOINCREMENT,
  article_id TEXT,
  title TEXT,
  stressor_name TEXT,
  stressor_units TEXT,
  specific_stressor_metric TEXT,
  species_common_name TEXT,
  species_latin TEXT,
  genus_latin TEXT,
  geography TEXT,
  activity TEXT,
  season TEXT,
  life_stages TEXT,
  citation_link TEXT,
  covariates_dependencies TEXT,
  description_overview TEXT,
  description_function_derivation TEXT,
  description_transferability_of_function TEXT,
  description_source_of_stressor_data1 TEXT,
  citations_citation_text TEXT,
  citations_citation_links TEXT,
  research_article_type TEXT,
  location_country TEXT,
  location_state_province TEXT,
  location_watershed_lab TEXT,
  location_river_creek TEXT,
  broad_stressor_name TEXT,
  csv_data_json TEXT
);

-- Step 3: Copy data from old table (excluding stressor_category)
INSERT INTO stressor_responses (
  main_id, article_id, title, stressor_name, stressor_units, specific_stressor_metric,
  species_common_name, species_latin, genus_latin, geography, activity, season, life_stages,
  citation_link, covariates_dependencies, description_overview,
  description_function_derivation, description_transferability_of_function,
  description_source_of_stressor_data1, citations_citation_text, citations_citation_links,
  research_article_type, location_country, location_state_province,
  location_watershed_lab, location_river_creek, broad_stressor_name, csv_data_json
)
SELECT
  main_id, article_id, title, stressor_name, stressor_units, specific_stressor_metric,
  species_common_name, species_latin, genus_latin, geography, activity, season, life_stages,
  citation_link, covariates_dependencies, description_overview,
  description_function_derivation, description_transferability_of_function,
  description_source_of_stressor_data1, citations_citation_text, citations_citation_links,
  research_article_type, location_country, location_state_province,
  location_watershed_lab, location_river_creek, broad_stressor_name, csv_data_json
FROM stressor_responses_old;

-- Step 4: Drop the old table
DROP TABLE stressor_responses_old;
