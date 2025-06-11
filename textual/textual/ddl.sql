DROP TABLE IF EXISTS lexical_tokens CASCADE;
DROP TABLE IF EXISTS lexical_stats CASCADE;
DROP TABLE IF EXISTS pos_bigrams CASCADE;
DROP TABLE IF EXISTS named_entities CASCADE;

-- Table to store token-level lexical and syntactic information for each 
-- Here, we have deep parsing
-- From this table, we can re-build our dependency graph
CREATE TABLE lexical_tokens (
    doc_id INT,          -- Identifier of the document/text sample
    label INT,           -- Class label (0=Human, 1=AI)
    sentence INT,        -- Sentence index within the document (0-based)
    position INT,        -- Token position within the sentence (0-based)
    token TEXT,          -- The actual token text (word form)
    lemma TEXT,          -- Lemmatized form of the token (dictionary form)
    pos TEXT,            -- Part-of-speech tag (coarse-grained, e.g., NOUN, VERB)
    tag TEXT,            -- Fine-grained POS tag (e.g., NN, VBD)
    is_stop BOOLEAN,     -- True if token is a stopword, False otherwise
    dep TEXT,            -- Dependency relation label (e.g., nsubj, dobj)
    head TEXT,            -- Position of the syntactic head token in the sentence (integer index)
    head_pos TEXT,       -- POS tag of the head token (helps identify head type)
    is_root BOOLEAN,     -- True if token is the root of the dependency tree
    depth INT,           -- Depth of the token in the dependency parse tree (root=0)
    num_children INT     -- Number of dependent children tokens this token has
);

-- Table to store aggregate lexical statistics per each doc
CREATE TABLE lexical_stats (
    doc_id INT,              -- Identifier of the document/text sample
    label INT,           	  -- Class label (0=Human, 1=AI)
    num_sentences INT,       -- Number of sentences in the document
    total_tokens INT,        -- Total number of tokens in the document
    unique_tokens INT,       -- Number of unique tokens in the document
    type_token_ratio FLOAT,  -- Lexical diversity = unique_tokens / total_tokens
    avg_token_length FLOAT,  -- Average length of tokens in characters
    hapax_legomena_ratio FLOAT, -- Ratio of hapax legomena (tokens occurring once) to total tokens
    pct_noun FLOAT,          -- Percentage of nouns in tokens (0 to 1)
    pct_verb FLOAT,          -- Percentage of verbs in tokens (0 to 1)
    pct_adj FLOAT,           -- Percentage of adjectives in tokens (0 to 1)
    pct_adv FLOAT            -- Percentage of adverbs in tokens (0 to 1)
);

-- Table to store bigrams in various docs
CREATE TABLE pos_bigrams (
    doc_id INT,          -- Identifier of the document/text sample
    label INT,           -- Class label (0=Human, 1=AI)
    pos_bigram TEXT,     -- Ordered part-of-speech bigram (e.g., 'NOUN_VERB')
    count INT            -- Frequency of the bigram in the document
);

-- 	Table to store extracted entity from docs
CREATE TABLE named_entities (
    doc_id INT,          -- Identifier of the document/text sample
    label INT,           			 -- Class label (0=Human, 1=AI-generated)
    entity_text  TEXT NOT NULL,     -- the actual entity string
    entity_label VARCHAR(50) NOT NULL,  -- entity type, e.g. PERSON, ORG, GPE
    start_char   INTEGER NOT NULL,  -- character offset of entity start in text
    end_char     INTEGER NOT NULL,  -- character offset of entity end in text
    sentence_idx INTEGER NOT NULL   -- sentence index (from ent.sent.start)
);