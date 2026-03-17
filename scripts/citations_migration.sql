-- ===============================================================================================================
-- Migration: stressor_responses.citation_text + stressor_responses.citation_links -> stressor_responses.citations
-- ===============================================================================================================

-- Step 1: Add new citations column (DONE)
ALTER TABLE stressor_responses.stressor_responses ADD COLUMN citations JSONB;

-- Step 2: Populate citations column by combining citation_text and citation_links (DONE)
UPDATE stressor_responses.stressor_responses sr
SET citations = (
  SELECT jsonb_agg(
    jsonb_build_object(
      'text',  sr.citation_text,
      'title', link->>'title',
      'url',   link->>'url'
    )
  )
  FROM jsonb_array_elements(sr.citation_links::jsonb) AS link
)
WHERE sr.citation_links IS NOT NULL
  AND sr.citation_links != ''       -- guard against empty strings
  AND sr.citation_links != '[]'
  AND sr.citation_links ~ '^\s*\['; -- guard against non-array JSON

-- Step 3: For rows with text but no links, store as a single object with just text (DONE)
UPDATE stressor_responses.stressor_responses
SET citations = jsonb_build_array(
  jsonb_build_object('text', stressor_responses.citation_text, 'title', NULL, 'url', NULL)
)
WHERE (stressor_responses.citation_links IS NULL OR stressor_responses.citation_links = '[]')
  AND stressor_responses.citation_text IS NOT NULL;

-- Step 4: Once verified, drop the old columns
ALTER TABLE stressor_responses.stressor_responses DROP COLUMN stressor_responses.citation_text;
ALTER TABLE stressor_responses.stressor_responses DROP COLUMN stressor_responses.citation_links;

-- NOTES:
-- citation_links already contains objects with title and url, and citation_text is just a longer-form description of the same source(s).
-- They belong together; a single citations column as a JSONB array of objects gives the most flexibility:
-- json[
--   {
--     "text": "Cramer, S. P., & Ackerman, N. K. (2009). Prediction of stream...",
--     "title": "Cramer & Ackerman 2009",
--     "url": "https://www.researchgate.net/..."
--   }
-- ]

-- Why JSONB over two separate columns
-- data already has a many-to-many problem.
--   some articles have one block of citation_text but multiple links (12 rows have 2+ links).
--   there's no clean way to pair them in a flat structure — the text and links don't always have a 1:1 correspondence.
-- JSONB is queryable.
--   unlike a plain TEXT JSON blob, PostgreSQL's JSONB lets you index and query into it, e.g. WHERE citations @> '[{"title": "Cramer"}]'.
--   It matches the pattern you're already using. Your citation_links column is already JSON — you're just formalizing and consolidating it.
--   It avoids a whole join table.
--     The alternative would be a separate citations table with its own citation_id, article_id, text, title, url
--       which is more normalized but adds complexity that isn't warranted unless you need to query citations independently across articles.

-- one caveat
--   For the 43 rows where citation_links is empty ([]), the text field will be populated but title and url will be null.
--   For the multi-citation text blocks (where one citation_text contains several references separated by newlines), you can't automatically split them cleanly.
--     those would stay as one object with a long text value until someone manually separates them.
--     That's a data quality issue to clean up over time, not a schema problem.