BEGIN TRANSACTION;

-- 1) Rename the old table
ALTER TABLE stressor_responses RENAME TO old_responses;

-- 2) Create the new table with main_id AUTOINCREMENT
CREATE TABLE stressor_responses (
  main_id     INTEGER PRIMARY KEY AUTOINCREMENT,
  article_id  INTEGER,         -- old NOAA ID
  title       TEXT,
  stressor_name               TEXT,
  stressor_units              TEXT,
  specific_stressor_metric    TEXT,
  species_common_name         TEXT,
  species_latin               TEXT,
  genus_latin                 TEXT,
  geography                   TEXT,
  activity                    TEXT,
  season                      TEXT,
  images                      TEXT,
  life_stages                 TEXT,
  citation_link               TEXT,
  covariates_dependencies     TEXT,
  stressor_scale              TEXT,
  function_type               TEXT,
  description_overview        TEXT,
  description_function_derivation TEXT,
  description_transferability_of_function TEXT,
  description_source_of_stressor_data1 TEXT,
  description_source_of_stressor_data2 TEXT,
  description_pathways_of_effect TEXT,
  citations_citation_text     TEXT,
  citations_citation_links    TEXT,
  csv_data_json               TEXT,
  stressor_category           TEXT,
  research_article_type       TEXT,
  location_country            TEXT,
  location_state_province     TEXT,
  location_watershed_lab      TEXT,
  location_river_creek        TEXT
);

-- 3) Copy data over, mapping id → article_id
INSERT INTO stressor_responses (
  article_id, title, stressor_name, stressor_units,
  specific_stressor_metric, species_common_name, species_latin,
  genus_latin, geography, activity, season, images, life_stages,
  citation_link, covariates_dependencies, stressor_scale, function_type,
  description_overview, description_function_derivation,
  description_transferability_of_function,
  description_source_of_stressor_data1,
  description_source_of_stressor_data2,
  description_pathways_of_effect,
  citations_citation_text, citations_citation_links,
  csv_data_json, stressor_category, research_article_type,
  location_country, location_state_province,
  location_watershed_lab, location_river_creek
)
SELECT
  id, title, stressor_name, stressor_units,
  specific_stressor_metric, species_common_name, species_latin,
  genus_latin, geography, activity, season, images, life_stages,
  citation_link, covariates_dependencies, stressor_scale, function_type,
  description_overview, description_function_derivation,
  description_transferability_of_function,
  description_source_of_stressor_data1,
  description_source_of_stressor_data2,
  description_pathways_of_effect,
  citations_citation_text, citations_citation_links,
  csv_data_json, stressor_category, research_article_type,
  location_country, location_state_province,
  location_watershed_lab, location_river_creek
FROM old_responses
ORDER BY rowid;

-- 4) Drop the old table
DROP TABLE old_responses;

COMMIT;
