-- Stressor Names
DELETE FROM stressor_names
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM stressor_names
  WHERE name IS NOT NULL AND TRIM(name) != ''
  GROUP BY LOWER(name)
);

-- Specific Stressor Metric
DELETE FROM stressor_metrics
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM stressor_metrics
  WHERE name IS NOT NULL AND TRIM(name) != ''
  GROUP BY LOWER(name)
);

-- Species Common Name
DELETE FROM species_common_names
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM species_common_names
  WHERE name IS NOT NULL AND TRIM(name) != ''
  GROUP BY LOWER(name)
);

-- Genus Latin
DELETE FROM genus_latins
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM genus_latins
  WHERE name IS NOT NULL AND TRIM(name) != ''
  GROUP BY LOWER(name)
);

-- Species Latin
DELETE FROM species_latins
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM species_latins
  WHERE name IS NOT NULL AND TRIM(name) != ''
  GROUP BY LOWER(name)
);

-- Geography
DELETE FROM geographies
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM geographies
  WHERE name IS NOT NULL AND TRIM(name) != ''
  GROUP BY LOWER(name)
);

-- Life Stage
DELETE FROM life_stages
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM life_stages
  WHERE name IS NOT NULL AND TRIM(name) != ''
  GROUP BY LOWER(name)
);

-- Activity
DELETE FROM activities
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM activities
  WHERE name IS NOT NULL AND TRIM(name) != ''
  GROUP BY LOWER(name)
);

-- Research Article Type
DELETE FROM research_article_types
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM research_article_types
  WHERE name IS NOT NULL AND TRIM(name) != ''
  GROUP BY LOWER(name)
);

-- Location Country
DELETE FROM location_countries
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM location_countries
  WHERE name IS NOT NULL AND TRIM(name) != ''
  GROUP BY LOWER(name)
);

-- State / Province
DELETE FROM location_states_provinces
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM location_states_provinces
  WHERE name IS NOT NULL AND TRIM(name) != ''
  GROUP BY LOWER(name)
);

-- Watershed / Lab
DELETE FROM location_watersheds_labs
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM location_watersheds_labs
  WHERE name IS NOT NULL AND TRIM(name) != ''
  GROUP BY LOWER(name)
);

-- River / Creek
DELETE FROM location_rivers_creeks
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM location_rivers_creeks
  WHERE name IS NOT NULL AND TRIM(name) != ''
  GROUP BY LOWER(name)
);

-- Broad Stressor Name
DELETE FROM broad_stressor_names
WHERE rowid NOT IN (
  SELECT MIN(rowid)
  FROM broad_stressor_names
  WHERE name IS NOT NULL AND TRIM(name) != ''
  GROUP BY LOWER(name)
);
