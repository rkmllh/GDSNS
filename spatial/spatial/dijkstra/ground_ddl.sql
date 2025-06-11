DROP TABLE IF EXISTS country_info;
DROP TABLE IF EXISTS country_edges;
DROP TABLE IF EXISTS exploration;
DROP TABLE IF EXISTS ocean_country_edges;
DROP TABLE IF EXISTS ocean_to_country_edge;
DROP TABLE IF EXISTS ocean_to_ocean_edges;
DROP TABLE IF EXISTS all_edges;

CREATE TABLE IF NOT EXISTS country_info AS
SELECT
  iso_a2    AS country_code,
  name,
  ST_Area(geom::geography) AS surface_area
FROM public.italy
WHERE iso_a2 ~ '^[A-Z]{2}$';    -- excludes "-99" and any other non‑ISO codes

CREATE TABLE IF NOT EXISTS country_edges AS
SELECT
  a.iso_a2 AS source,
  b.iso_a2 AS target,
  ci.surface_area AS cost
FROM public.italy a
JOIN public.italy b
  ON ST_Touches(a.geom, b.geom)
JOIN country_info ci
  ON b.iso_a2 = ci.country_code
WHERE a.iso_a2 ~ '^[A-Z]{2}$'
  AND b.iso_a2 ~ '^[A-Z]{2}$';  -- drop any edges involving the "-99" features

-- Indici su source e target per velocizzare la ricerca dei vicini

CREATE INDEX ON country_edges (source);
CREATE INDEX ON country_edges (target);

-- Tabella per tenere traccia del costo minimo verso ogni nodo
CREATE TEMP TABLE IF NOT EXISTS exploration (
  country VARCHAR PRIMARY KEY,
  total_cost FLOAT,
  path VARCHAR[]
);
