COPY lexical_tokens (
    doc_id,
    label,
    sentence,
    position,
    token,
    lemma,
    pos,
    tag,
    is_stop,
    dep,
    head,
    head_pos,
    is_root,
    depth,
    num_children
)FROM 'C:\Users\walte\OneDrive\Desktop\computerman\corsi\GDSNS\NonStrutturati\NonStrutturati\testuale\Training_Essay_Data.csv\deep_parsed_tokens.csv' 
DELIMITER ',' CSV HEADER;

COPY lexical_stats (
    doc_id,
    label,
    num_sentences,
    total_tokens,
    unique_tokens,
    type_token_ratio,
    avg_token_length,
    hapax_legomena_ratio,
    pct_noun,
    pct_verb,
    pct_adj,
    pct_adv
)
FROM 'C:/Users/walte/OneDrive/Desktop/computerman/corsi/GDSNS/NonStrutturati/NonStrutturati/testuale/Training_Essay_Data.csv/lexical_stats.csv'
WITH (FORMAT csv, HEADER true);

COPY pos_bigrams (doc_id, label, pos_bigram, count)
FROM 'C:/Users/walte/OneDrive/Desktop/computerman/corsi/GDSNS/NonStrutturati/NonStrutturati/testuale/Training_Essay_Data.csv/pos_bigrams.csv'
WITH (FORMAT csv, HEADER true);

COPY named_entities (doc_id, label, entity_text, entity_label, start_char, end_char, sentence_idx)
FROM 'C:/Users/walte/OneDrive/Desktop/computerman/corsi/GDSNS/NonStrutturati/NonStrutturati/testuale/Training_Essay_Data.csv/named_entities.csv'
WITH (FORMAT csv, HEADER true);

-- Use HUMAN and AI 
ALTER TABLE lexical_tokens
ALTER COLUMN label TYPE TEXT
USING CASE label 
        WHEN 0 THEN 'HUMAN'
        WHEN 1 THEN 'AI' 
      END;

ALTER TABLE lexical_stats
ALTER COLUMN label TYPE TEXT
USING CASE label 
        WHEN 0 THEN 'HUMAN'
        WHEN 1 THEN 'AI' 
      END;

ALTER TABLE pos_bigrams
ALTER COLUMN label TYPE TEXT
USING CASE label 
        WHEN 0 THEN 'HUMAN'
        WHEN 1 THEN 'AI' 
      END;

ALTER TABLE named_entities
ALTER COLUMN label TYPE TEXT
USING CASE label 
        WHEN 0 THEN 'HUMAN'
        WHEN 1 THEN 'AI' 
      END;