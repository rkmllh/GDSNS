DROP TABLE IF EXISTS richman         		CASCADE;
DROP TABLE IF EXISTS country         		CASCADE;
DROP TABLE IF EXISTS country_stats         CASCADE;
DROP TABLE IF EXISTS exp_temp         		CASCADE;

CREATE TABLE country (
  iso_a3     CHAR(8)        PRIMARY KEY,
  name       TEXT           UNIQUE NOT NULL,
  type       TEXT,
  abbrev     TEXT,
  postal     CHAR(8),
  formal_en  TEXT,
  pop_est    DOUBLE PRECISION,
  pop_year   INT,
  economy    TEXT,
  income_grp TEXT,
  subregion  TEXT,
  name_en    TEXT,
  geom       geometry(MultiPolygon, 4326)
);

-- We create a super table holding the shared columns (country, year, value)
CREATE TABLE country_stats (
  country   CHAR(8)           NOT NULL,
  year      INT               NOT NULL,
  value     DOUBLE PRECISION  NOT NULL
);

CREATE TABLE expectation_life (
) INHERITS (country_stats);

ALTER TABLE expectation_life
  ADD CONSTRAINT pk_expectation_country_year
    PRIMARY KEY (country, year);

ALTER TABLE expectation_life
  ADD CONSTRAINT fk_expectation_country
    FOREIGN KEY (country)
    REFERENCES country(iso_a3)
      ON UPDATE CASCADE
      ON DELETE CASCADE;

CREATE TABLE emission (
  source  TEXT
) INHERITS (country_stats);

ALTER TABLE emission
  ADD CONSTRAINT pk_emission_country_year
    PRIMARY KEY (country, year);

ALTER TABLE emission
  ADD CONSTRAINT fk_emission_country
    FOREIGN KEY (country)
    REFERENCES country(iso_a3)
      ON UPDATE CASCADE
      ON DELETE CASCADE;

CREATE TABLE indicator (
  source  TEXT,
  par     TEXT
) INHERITS (country_stats);

ALTER TABLE indicator
  ADD CONSTRAINT pk_indicator_country_year
    PRIMARY KEY (country, par, year);

ALTER TABLE indicator
  ADD CONSTRAINT fk_indicator_country
    FOREIGN KEY (country)
    REFERENCES country(iso_a3)
      ON UPDATE CASCADE
      ON DELETE CASCADE;

-- (independent of country_stats)
CREATE TABLE richman (
  id           SERIAL    PRIMARY KEY,
  name         TEXT      NOT NULL,
  age          INT,
  sector       TEXT,
  gender       TEXT,
  ranking      INT,
  title        TEXT,
  self_made    BOOLEAN,
  organization TEXT,
  country      CHAR(8)       NOT NULL,

  CONSTRAINT fk_richman_country
    FOREIGN KEY (country)
    REFERENCES country(iso_a3)
      ON UPDATE CASCADE
      ON DELETE RESTRICT
);

CREATE TABLE exp_temp (
  iso3                        CHAR(3),
  country                     TEXT,
  continent                   TEXT,
  hemisphere                  TEXT,
  human_development_group     TEXT,
  undp_developing_region      TEXT,
  hdi_rank_2021               INTEGER,
  life_expectancy_1990        DOUBLE PRECISION,
  life_expectancy_1991        DOUBLE PRECISION,
  life_expectancy_1992        DOUBLE PRECISION,
  life_expectancy_1993        DOUBLE PRECISION,
  life_expectancy_1994        DOUBLE PRECISION,
  life_expectancy_1995        DOUBLE PRECISION,
  life_expectancy_1996        DOUBLE PRECISION,
  life_expectancy_1997        DOUBLE PRECISION,
  life_expectancy_1998        DOUBLE PRECISION,
  life_expectancy_1999        DOUBLE PRECISION,
  life_expectancy_2000        DOUBLE PRECISION,
  life_expectancy_2001        DOUBLE PRECISION,
  life_expectancy_2002        DOUBLE PRECISION,
  life_expectancy_2003        DOUBLE PRECISION,
  life_expectancy_2004        DOUBLE PRECISION,
  life_expectancy_2005        DOUBLE PRECISION,
  life_expectancy_2006        DOUBLE PRECISION,
  life_expectancy_2007        DOUBLE PRECISION,
  life_expectancy_2008        DOUBLE PRECISION,
  life_expectancy_2009        DOUBLE PRECISION,
  life_expectancy_2010        DOUBLE PRECISION,
  life_expectancy_2011        DOUBLE PRECISION,
  life_expectancy_2012        DOUBLE PRECISION,
  life_expectancy_2013        DOUBLE PRECISION,
  life_expectancy_2014        DOUBLE PRECISION,
  life_expectancy_2015        DOUBLE PRECISION,
  life_expectancy_2016        DOUBLE PRECISION,
  life_expectancy_2017        DOUBLE PRECISION,
  life_expectancy_2018        DOUBLE PRECISION,
  life_expectancy_2019        DOUBLE PRECISION,
  life_expectancy_2020        DOUBLE PRECISION,
  life_expectancy_2021        DOUBLE PRECISION
);