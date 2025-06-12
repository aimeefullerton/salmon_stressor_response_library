-- Populate original filters
INSERT OR IGNORE INTO stressor_names(name)
SELECT DISTINCT stressor_name FROM stressor_responses WHERE stressor_name IS NOT NULL;

INSERT OR IGNORE INTO stressor_metrics(name)
SELECT DISTINCT specific_stressor_metric FROM stressor_responses WHERE specific_stressor_metric IS NOT NULL;

INSERT OR IGNORE INTO species_common_names(name)
SELECT DISTINCT species_common_name FROM stressor_responses WHERE species_common_name IS NOT NULL;

INSERT OR IGNORE INTO geographies(name)
SELECT DISTINCT geography FROM stressor_responses WHERE geography IS NOT NULL;

INSERT OR IGNORE INTO life_stages(name)
SELECT DISTINCT TRIM(value)
FROM stressor_responses, 
     json_each('["' || REPLACE(life_stages, ',', '","') || '"]')
WHERE life_stages IS NOT NULL;

INSERT OR IGNORE INTO activities(name)
SELECT DISTINCT activity FROM stressor_responses WHERE activity IS NOT NULL;

INSERT OR IGNORE INTO genus_latins(name)
SELECT DISTINCT genus_latin FROM stressor_responses WHERE genus_latin IS NOT NULL;

INSERT OR IGNORE INTO species_latins(name)
SELECT DISTINCT species_latin FROM stressor_responses WHERE species_latin IS NOT NULL;

-- Populate new metadata filters
INSERT OR IGNORE INTO research_article_types(name)
SELECT DISTINCT research_article_type FROM stressor_responses WHERE research_article_type IS NOT NULL;

INSERT OR IGNORE INTO location_countries(name)
SELECT DISTINCT location_country FROM stressor_responses WHERE location_country IS NOT NULL;

INSERT OR IGNORE INTO location_states_provinces(name)
SELECT DISTINCT location_state_province FROM stressor_responses WHERE location_state_province IS NOT NULL;

INSERT OR IGNORE INTO location_watersheds_labs(name)
SELECT DISTINCT location_watershed_lab FROM stressor_responses WHERE location_watershed_lab IS NOT NULL;

INSERT OR IGNORE INTO location_rivers_creeks(name)
SELECT DISTINCT location_river_creek FROM stressor_responses WHERE location_river_creek IS NOT NULL;

INSERT OR IGNORE INTO broad_stressor_names(name)
SELECT DISTINCT broad_stressor_name FROM stressor_responses WHERE broad_stressor_name IS NOT NULL;
