-- *************************************************************
-- 1. Select bigram (got by POS) most frequent for classes.    *
-- *************************************************************
CREATE OR REPLACE VIEW top_bigram_percentages AS
WITH bigram_sums AS (
    SELECT
        label,
        pos_bigram,
        SUM(count) AS total_bigram_count
    FROM
        pos_bigrams
    GROUP BY
        label, pos_bigram
),
label_totals AS (
    SELECT
        label,
        SUM(total_bigram_count) AS total_label_bigrams
    FROM
        bigram_sums
    GROUP BY
        label
),
percentages AS (
    SELECT
        b.label,
        b.pos_bigram,
        ROUND((b.total_bigram_count::numeric / t.total_label_bigrams) * 100, 3) AS percentage
    FROM
        bigram_sums b
    JOIN
        label_totals t ON b.label = t.label
)
SELECT
    label,
    pos_bigram,
    percentage
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY label ORDER BY percentage DESC) AS rn
    FROM
        percentages
) ranked
WHERE rn <= 10;

SELECT * FROM top_bigram_percentages ORDER BY percentage DESC;

-- ******************************************************************************
-- 2 Select just a bigram, p_bigram, and get percentages for all classes.       *
-- ******************************************************************************
CREATE OR REPLACE FUNCTION get_top_bigram(p_bigram TEXT)
RETURNS TABLE (
  label       TEXT,
  pos_bigram  TEXT,
  percentage  NUMERIC
)
AS $$
BEGIN
  RETURN QUERY
  SELECT
    v.label,
    v.pos_bigram,
    v.percentage
  FROM
    top_bigram_percentages AS v
  WHERE
    v.pos_bigram = p_bigram
  ORDER BY
    v.percentage DESC;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_top_bigram('ADJ_NOUN');

-- ****************************************************************************************************************************************
-- 3 It calculates, for each class,                                                                                            * 
-- the average lexical diversity, the average hapax legomena ratio, and the correlation between these two metrics across documents.       *
-- ****************************************************************************************************************************************
SELECT
  label,
  ROUND(AVG(type_token_ratio)::numeric, 3)        AS avg_type_token_ratio,
  ROUND(AVG(hapax_legomena_ratio)::numeric, 3)    AS avg_hapax_legomena_ratio,
  ROUND(CORR(type_token_ratio, hapax_legomena_ratio)::numeric, 3) 
                                                  AS corr_diversity_hapax
FROM
  lexical_stats
GROUP BY
  label;

-- *********************************************************************************************************************************************************
-- 4 It computes, for each group (HUMAN/AI), the average syntactic parse depth and its correlation with lexical diversity across documents.                *
-- *********************************************************************************************************************************************************
WITH doc_depth AS (
  SELECT
    doc_id,
    AVG(depth)::NUMERIC AS avg_parse_depth
  FROM
    lexical_tokens
  GROUP BY
    doc_id
)
SELECT
  s.label,
  ROUND(AVG(d.avg_parse_depth)::NUMERIC, 3)       AS avg_parse_depth,
  ROUND(CORR(d.avg_parse_depth, s.type_token_ratio)::NUMERIC, 3)
                                                  AS corr_depth_diversity
FROM
  doc_depth d
  JOIN lexical_stats s USING (doc_id)
GROUP BY
  s.label
ORDER BY
  s.label;

-- ***************************************************************************************************************************************
-- 5 Find the top 40 most frequent root verbs (based on lemmas) used as the syntactic root of sentences,
-- separately for HUMAN and AI texts, and calculates their percentage frequency within each group.
-- ***************************************************************************************************************************************
WITH root_verbs AS (
  SELECT
    label,
    lemma AS root_verb,
    COUNT(*) AS freq
  FROM lexical_tokens
  WHERE dep = 'ROOT' AND pos = 'VERB'
  GROUP BY label, lemma
),
label_totals AS (
  SELECT
    label,
    SUM(freq) AS total
  FROM root_verbs
  GROUP BY label
),
percentages AS (
  SELECT
    rv.label,
    rv.root_verb,
    ROUND((rv.freq::numeric / lt.total) * 100, 2) AS percentage
  FROM root_verbs rv
  JOIN label_totals lt ON rv.label = lt.label
),
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY label ORDER BY percentage DESC) AS rn
  FROM percentages
)
SELECT
  label,
  root_verb,
  percentage
FROM ranked
WHERE rn <= 40
ORDER BY percentage DESC;

-- ************************************************************************************************************************************************************
-- 6. Find the average proportion of each major part of speech (nouns, adjectives, adverbs, verbs) used in documents, separately for HUMAN and AI labels.      *
-- ************************************************************************************************************************************************************
SELECT label, AVG(pct_noun) AS noun, AVG(pct_adj) AS adj, AVG(pct_adv) AS adv, AVG(pct_verb) AS verb FROM lexical_stats GROUP BY label;

-- *********************************************************************************************************************************************************************
-- 7. It computes the average percentage of passive verb constructions for each class.
-- *********************************************************************************************************************************************************************
WITH doc_passives AS (
  SELECT
    doc_id,
    COUNT(*) FILTER (WHERE dep = 'nsubjpass')         AS passive_count,
    COUNT(*) FILTER (WHERE pos = 'VERB')              AS verb_count
  FROM lexical_tokens
  GROUP BY doc_id
),
doc_passive_pct AS (
  SELECT
    doc_id,
    CASE 
      WHEN verb_count = 0 THEN 0
      ELSE (passive_count::NUMERIC / verb_count) * 100
    END AS passive_pct
  FROM doc_passives
)
SELECT
  s.label,
  ROUND(AVG(d.passive_pct)::NUMERIC, 2) AS avg_passive_pct
FROM doc_passive_pct d
JOIN lexical_stats s USING (doc_id)
GROUP BY s.label
ORDER BY s.label;

-- ********************************************************************************
-- 8. It computes the average sentence length in tokens for HUMAN and AI texts.   *
-- ********************************************************************************

SELECT
  label,
  ROUND(AVG(total_tokens::NUMERIC / NULLIF(num_sentences, 0)), 2) AS avg_sentence_length
FROM
  lexical_stats
GROUP BY
  label
ORDER BY
  label;
  
-- *********************************************************************************************
-- 9. Find which part-of-speech appears most often as the root of a sentence, per each class.   *
-- *********************************************************************************************
WITH root_counts AS (
  SELECT
    label,
    pos,
    COUNT(*) AS root_count
  FROM lexical_tokens
  WHERE is_root = TRUE
  GROUP BY label, pos
),
total_roots AS (
  SELECT
    label,
    COUNT(*) AS total_count
  FROM lexical_tokens
  WHERE is_root = TRUE
  GROUP BY label
)
SELECT
  r.label,
  r.pos,
  ROUND((r.root_count::NUMERIC / t.total_count) * 100, 2) AS percentage
FROM root_counts r
JOIN total_roots t ON r.label = t.label
ORDER BY percentage DESC;

-- *******************************************************************************************************
-- 10. It computes how frequently each dependency label (grammar relationship) occurs for each class.    *
-- *******************************************************************************************************
WITH dep_counts AS (
  SELECT
    label,
    dep,
    COUNT(*) AS freq
  FROM lexical_tokens
  GROUP BY label, dep
),
total_per_label AS (
  SELECT
    label,
    SUM(freq) AS total
  FROM dep_counts
  GROUP BY label
)
SELECT
  d.label,
  d.dep,
  ROUND((d.freq::numeric / t.total) * 100, 2) AS percentage
FROM dep_counts d
JOIN total_per_label t ON d.label = t.label
ORDER BY percentage DESC;

-- **************************************************************************************************************************************************
-- 11. Find the relative frequencies of different entity types (entity_label) found in two classes of documents labeled as 'HUMAN' and 'AI'.        *
-- **************************************************************************************************************************************************
WITH counts AS (
  SELECT label, entity_label, COUNT(*) AS cnt
  FROM named_entities
  GROUP BY label, entity_label
),
totals AS (
  SELECT label, SUM(cnt) AS total
  FROM counts
  GROUP BY label
),
freqs AS (
  SELECT c.label, c.entity_label, c.cnt, t.total, (c.cnt::float / t.total) AS freq
  FROM counts c
  JOIN totals t ON c.label = t.label
)
SELECT 
  f1.entity_label,
  f1.freq AS freq_human,
  f2.freq AS freq_ai,
  ABS(f1.freq - f2.freq) AS freq_diff
FROM freqs f1
JOIN freqs f2 ON f1.entity_label = f2.entity_label 
WHERE f1.label = 'HUMAN' AND f2.label = 'AI'
ORDER BY freq_diff DESC
LIMIT 10;

SELECT * FROM lexical_tokens;
SELECT * FROM lexical_stats;
SELECT * FROM pos_bigrams;
SELECT * FROM named_entities;