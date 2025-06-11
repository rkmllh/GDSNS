-- Let's populate country table form italy table --

DELETE FROM italy WHERE iso_a3 = '-99';

CREATE OR REPLACE FUNCTION populate_country_from_italy()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO country (
    iso_a3,
    name,
    type,
    abbrev,
    postal,
    formal_en,
    pop_est,
    pop_year,
    economy,
    income_grp,
    subregion,
    name_en,
	geom
  )
  SELECT
    i.iso_a3,
    i.name,
    i.type,
    i.abbrev,
    i.postal,
    i.formal_en,
    i.pop_est,
    i.pop_year,
    i.economy,
    i.income_grp,
    i.subregion,
    i.name_en,
	geom
  FROM italy AS i;
END;
$$;

SELECT populate_country_from_italy();

-- Let's populate expectation_life --

COPY exp_temp(
  iso3,
  country,
  continent,
  hemisphere,
  human_development_group,
  undp_developing_region,
  hdi_rank_2021,
  life_expectancy_1990,
  life_expectancy_1991,
  life_expectancy_1992,
  life_expectancy_1993,
  life_expectancy_1994,
  life_expectancy_1995,
  life_expectancy_1996,
  life_expectancy_1997,
  life_expectancy_1998,
  life_expectancy_1999,
  life_expectancy_2000,
  life_expectancy_2001,
  life_expectancy_2002,
  life_expectancy_2003,
  life_expectancy_2004,
  life_expectancy_2005,
  life_expectancy_2006,
  life_expectancy_2007,
  life_expectancy_2008,
  life_expectancy_2009,
  life_expectancy_2010,
  life_expectancy_2011,
  life_expectancy_2012,
  life_expectancy_2013,
  life_expectancy_2014,
  life_expectancy_2015,
  life_expectancy_2016,
  life_expectancy_2017,
  life_expectancy_2018,
  life_expectancy_2019,
  life_expectancy_2020,
  life_expectancy_2021
)
FROM 'C:/Users/walte/OneDrive/Desktop/computerman/corsi/GDSNS/NonStrutturati/NonStrutturati/train/expectation.csv'
WITH (
  FORMAT CSV,
  HEADER TRUE,
  DELIMITER ','
);

INSERT INTO expectation_life (country, year, value)
SELECT c.iso_a3, 1990, e.life_expectancy_1990 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 1991, e.life_expectancy_1991 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 1992, e.life_expectancy_1992 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 1993, e.life_expectancy_1993 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 1994, e.life_expectancy_1994 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 1995, e.life_expectancy_1995 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 1996, e.life_expectancy_1996 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 1997, e.life_expectancy_1997 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 1998, e.life_expectancy_1998 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 1999, e.life_expectancy_1999 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2000, e.life_expectancy_2000 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2001, e.life_expectancy_2001 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2002, e.life_expectancy_2002 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2003, e.life_expectancy_2003 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2004, e.life_expectancy_2004 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2005, e.life_expectancy_2005 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2006, e.life_expectancy_2006 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2007, e.life_expectancy_2007 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2008, e.life_expectancy_2008 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2009, e.life_expectancy_2009 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2010, e.life_expectancy_2010 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2011, e.life_expectancy_2011 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2012, e.life_expectancy_2012 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2013, e.life_expectancy_2013 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2014, e.life_expectancy_2014 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2015, e.life_expectancy_2015 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2016, e.life_expectancy_2016 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2017, e.life_expectancy_2017 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2018, e.life_expectancy_2018 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2019, e.life_expectancy_2019 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2020, e.life_expectancy_2020 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3
UNION ALL
SELECT c.iso_a3, 2021, e.life_expectancy_2021 FROM exp_temp e JOIN country c ON e.iso3 = c.iso_a3;

-- A small ddl step, but necessary! Uncomment to retiain space.
-- DROP TABLE exp_temp;

COPY richman(ranking, name, age, sector, gender, title, self_made, organization, country)
FROM 'dataset_aspatial/billionaires_clean.csv'
WITH (FORMAT csv, HEADER true);

COPY emission(country, year, value, source)
FROM 'dataset_aspatial\emission_clean.csv'
WITH (FORMAT csv, HEADER true);

COPY indicator(country, par, source, year, value)
FROM 'dataset_aspatial\indicator_clean.csv'
WITH (FORMAT csv, HEADER true);

ALTER TABLE indicator DROP COLUMN source;