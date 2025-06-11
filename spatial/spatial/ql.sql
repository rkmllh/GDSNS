-- QL for us

SELECT * FROM country;

SELECT * FROM emission;

SELECT * FROM indicator;

SELECT * FROM richman;

SELECT * FROM expectation_life;

-- 1. Countries bordering a fixed country that have at least one wealthy man.
-- 2. Countries bordered by seas/lakes that have at least one wealthy man.
-- 3. Countries bordered by seas/lakes where emissions from _start_year to _end_year had an average above _threshold.
-- 4. Landlocked countries that have at least one wealthy man.
-- 5. Comparison between maritime countries and inland countries regarding emissions.
-- 6. Comparison between maritime countries and inland countries regarding the average of a certain indicator parameter.
-- 7. Countries that completely contain any type of water resource and have at least one wealthy man.
-- 8. Maritime countries with their average emissions from start_year to end_year and surface area, ordered by highest average emissions.
-- 9. Average age of wealthy men, divided by layer.
-- 10. Country closest to a given point that has an average emission above a certain threshold within a range of years.

-- 1. Countries neighboring center_iso (i.e., a certain input country) that have at least one wealthy man.
CREATE OR REPLACE FUNCTION get_rich_neighbors(center_iso CHAR(8))
  RETURNS TABLE (
    neighbor_iso   CHAR(8),
    neighbor_name  TEXT,
    richman_count  INT
  )
AS $$
BEGIN
  RETURN QUERY
  SELECT
    n.iso_a3,
    n.name,
    COUNT(r.id)::INT AS richman_count
  FROM
    country    AS c
    JOIN country AS n
      ON ST_Touches(c.geom, n.geom)
    JOIN richman AS r
      ON r.country = n.iso_a3
  WHERE
    c.iso_a3 = center_iso
  GROUP BY
    n.iso_a3,
    n.name
  HAVING
    COUNT(r.id) >= 1
  ORDER BY
    richman_count DESC;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_rich_neighbors('ITA');

-- 2. Countries bordering seas/lakes that have at least one wealthy man.
SELECT
  c.iso_a3,
  c.name,
  COUNT(DISTINCT r.id) AS richman_count
FROM country AS c
JOIN oceans   AS o ON ST_Intersects(c.geom, o.geom)
JOIN richman AS r ON r.country = c.iso_a3
GROUP BY
  c.iso_a3,
  c.name
HAVING
  COUNT(DISTINCT r.id) >= 1
ORDER BY
  richman_count DESC;

-- 3. Countries bordering seas/lakes where emissions from _start_year to _end_year had an average above _threshold.
CREATE OR REPLACE FUNCTION get_water_border_avg_emission(
  _start_year INT,
  _end_year   INT,
  _threshold  DOUBLE PRECISION
)
RETURNS TABLE (
  iso_a3       CHAR(8),
  name         TEXT,
  avg_emission DOUBLE PRECISION
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
    SELECT
      c.iso_a3,
      c.name,
      AVG(e.value)::DOUBLE PRECISION AS avg_emission
    FROM country   AS c
    JOIN emission  AS e
      ON e.country = c.iso_a3
    WHERE
      e.year BETWEEN _start_year AND _end_year
      AND EXISTS ( 
        SELECT 1
        FROM oceans AS o
        WHERE ST_Intersects(c.geom, o.geom)
      )
    GROUP BY c.iso_a3, c.name
    HAVING AVG(e.value) > _threshold
    ORDER BY avg_emission DESC;
END;
$$;

-- From 2005 to 2020, with an average emission above 150.
SELECT * FROM get_water_border_avg_emission(2005, 2020, 150);

-- 4. Landlocked countries that have at least one wealthy man.
SELECT
  c.iso_a3,
  c.name,
  COUNT(DISTINCT r.id) AS richmen
FROM country   AS c
JOIN richman   AS r  ON r.country = c.iso_a3
WHERE NOT EXISTS (
  SELECT 1
  FROM oceans AS o
  WHERE ST_Intersects(c.geom, o.geom)
)
GROUP BY
  c.iso_a3,
  c.name
ORDER BY
  richmen DESC;

-- 5. Comparison between maritime countries and inland countries regarding emissions.
CREATE OR REPLACE FUNCTION compare_coastal_landlocked_emissions(
  _start_year INT,
  _end_year   INT
)
RETURNS TABLE (
  category          TEXT,
  avg_emission      DOUBLE PRECISION,
  num_countries     INT
)
LANGUAGE plpgsql STABLE
AS $$
BEGIN
  RETURN QUERY
  WITH 
  coastal AS (
    SELECT iso_a3
    FROM country c
    WHERE EXISTS (
      SELECT 1
      FROM oceans o
      WHERE ST_Intersects(c.geom, o.geom)
    )
  ),
  country_type AS (
    SELECT
      c.iso_a3,
      CASE
        WHEN c.iso_a3 IN (SELECT iso_a3 FROM coastal) THEN 'coastal'
        ELSE 'landlocked'
      END AS type
    FROM country c
  ),
  avg_em_by_country AS (
    SELECT
      e.country,
      AVG(e.value) AS avg_emission
    FROM emission e
    WHERE e.year BETWEEN _start_year AND _end_year
    GROUP BY e.country
  )
  SELECT
    ct.type                    AS category,
    ROUND(AVG(a.avg_emission)::numeric, 4)::DOUBLE PRECISION AS avg_emission,
    COUNT(a.country)::INT      AS num_countries
  FROM country_type ct
  JOIN avg_em_by_country a
    ON a.country = ct.iso_a3
  GROUP BY ct.type
  ORDER BY ct.type;
END;
$$;

SELECT * FROM compare_coastal_landlocked_emissions(1940, 2020);

-- 6. Comparison between maritime countries and inland countries regarding the average of an indicator parameter.
CREATE OR REPLACE FUNCTION avg_indicator_by_country_type(
  param_name TEXT,
  start_year INT,
  end_year INT
)
RETURNS TABLE (
  country_type TEXT,
  avg_indicator NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH indicator_avg_per_country AS (
    SELECT
      i.country,
      AVG(i.value) AS avg_val
    FROM indicator i
    WHERE i.par = param_name
      AND i.year BETWEEN start_year AND end_year
    GROUP BY i.country
  ),
  country_type_classified AS (
    SELECT
      c.iso_a3,
      CASE
        WHEN EXISTS (
          SELECT 1
          FROM oceans o
          WHERE ST_Intersects(c.geom, o.geom)
        )
        THEN 'marine'
        ELSE 'landlocked'
      END AS country_type
    FROM country c
  )
  SELECT
    ct.country_type,
    ROUND(AVG(ind.avg_val)::NUMERIC, 2)
  FROM indicator_avg_per_country ind
  JOIN country_type_classified ct ON ct.iso_a3 = ind.country
  GROUP BY ct.country_type
  ORDER BY ct.country_type;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM avg_indicator_by_country_type('Forest area', 1997, 2008);

-- 7. Countries that completely contain any type of water resource and have at least one wealthy man.
SELECT DISTINCT
  c.iso_a3,
  c.name
FROM country c
JOIN richman r ON r.country = c.iso_a3
JOIN oceans o ON ST_Contains(c.geom, o.geom)
WHERE r.country = c.iso_a3;

-- 8. Maritime countries with their average emissions from start_year to end_year and surface area, ordered by highest average emissions.
CREATE OR REPLACE FUNCTION get_marine_countries_avg_emission(
  _start_year INT,
  _end_year INT,
  _min_avg_emission DOUBLE PRECISION DEFAULT 0
)
RETURNS TABLE (
  iso_a3 CHAR(8),
  name TEXT,
  avg_emission NUMERIC,
  area_sqm NUMERIC
)
LANGUAGE sql
AS $$
WITH marine_countries_avg_emission AS (
  SELECT
    c.iso_a3,
    c.name,
    AVG(e.value) AS avg_emission,
    ST_Area(c.geom) AS area
  FROM country c
  JOIN emission e ON e.country = c.iso_a3
  WHERE
    e.year BETWEEN _start_year AND _end_year
    AND EXISTS (
      SELECT 1
      FROM oceans o
      WHERE ST_Intersects(c.geom, o.geom)
    )
  GROUP BY c.iso_a3, c.name, c.geom
)
SELECT
  iso_a3,
  name,
  ROUND(avg_emission::numeric, 2) AS avg_emission,
  ROUND(area) AS area_sqm
FROM marine_countries_avg_emission
WHERE avg_emission >= _min_avg_emission
ORDER BY avg_emission DESC;
$$;

SELECT * FROM get_marine_countries_avg_emission(1995, 2020, 0);

-- 9. Average age of wealthy men, grouped by layer.
WITH marine_countries AS (
  SELECT DISTINCT c.iso_a3
  FROM country c
  JOIN oceans o
    ON ST_Intersects(c.geom, o.geom)  -- Countries intersecting sea/lake
),
richman_classification AS (
  SELECT 
    r.age,
    CASE 
      WHEN c.iso_a3 IN (SELECT iso_a3 FROM marine_countries) THEN 'marine'
      ELSE 'inland'
    END AS country_type
  FROM richman r
  JOIN country c ON r.country = c.iso_a3
  WHERE r.age IS NOT NULL
)
SELECT 
  country_type,
  AVG(age)::NUMERIC(5,2) AS average_age
FROM richman_classification
GROUP BY country_type;

-- 10. Countries closest to a given point that have an average emission above a certain threshold within a range of years.
CREATE OR REPLACE FUNCTION closest_high_emission_country(
  lon DOUBLE PRECISION,           -- long of reference
  lat DOUBLE PRECISION,           -- lat of reference
  start_year INT,                 
  end_year INT,
  threshold DOUBLE PRECISION      -- for emissions
)
RETURNS TABLE (
  country_name TEXT,
  avg_emission DOUBLE PRECISION,
  distance_meters DOUBLE PRECISION  	-- from reference
)
AS $$
BEGIN
  RETURN QUERY
  WITH reference_point AS (
    SELECT ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography AS ref_geom
  ),
  emission_avg AS (
    SELECT country, AVG(value) AS avg_emission
    FROM emission
    WHERE year BETWEEN start_year AND end_year
    GROUP BY country
    HAVING AVG(value) > threshold
  ),
  centroids AS (
    SELECT 
      c.iso_a3,
      c.name,
      ST_Centroid(c.geom)::geography AS center_geom
    FROM country c
  )
  SELECT 
    ce.name,
    ea.avg_emission,
    ST_Distance(ce.center_geom, rp.ref_geom) AS distance_meters
  FROM centroids ce
  JOIN emission_avg ea ON ea.country = ce.iso_a3
  CROSS JOIN reference_point rp
  ORDER BY distance_meters
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- (12.4964, 41.9028) is Rome
-- Feel free to test other points
SELECT * FROM closest_high_emission_country(12.4964, 41.9028, 2010, 2020, 100); -- 100 is our threshold