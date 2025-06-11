DROP TABLE IF EXISTS country_info;
DROP TABLE IF EXISTS country_edges;
DROP TABLE IF EXISTS exploration;
DROP TABLE IF EXISTS ocean_country_edges;
DROP TABLE IF EXISTS ocean_to_country_edge;
DROP TABLE IF EXISTS ocean_to_ocean_edges;
DROP TABLE IF EXISTS all_edges;

UPDATE public.italy 
	SET iso_a2 = case name
		WHEN 'France' THEN 'FR'
		WHEN 'Norway' THEN 'NO'
		WHEN 'Kosovo' THEN 'XK'
 		ELSE iso_a2
	END
WHERE NAME IN ('France','Norway','Kosovo');

DROP TABLE IF EXISTS country_info;
CREATE TABLE country_info AS
SELECT iso_a2 AS country_code,
       name,
       ST_Area(geom::geography) AS surface_area
  FROM public.italy
 WHERE iso_a2 ~ '^[A-Z]{2}$';    -- drop “-99” codes 

DROP TABLE IF EXISTS country_edges;
CREATE TABLE country_edges AS
SELECT a.iso_a2        AS source,
       b.iso_a2        AS target,
       ci.surface_area AS cost
  FROM public.italy a
  JOIN public.italy b
    ON ST_Touches(a.geom, b.geom)   -- strict land adjacency, or Intersection??
  JOIN country_info ci
    ON b.iso_a2 = ci.country_code
 WHERE a.iso_a2 ~ '^[A-Z]{2}$'
   AND b.iso_a2 ~ '^[A-Z]{2}$';

CREATE INDEX ON country_edges(source);
CREATE INDEX ON country_edges(target);

-- Ensure spatial indexes on geometry
CREATE INDEX IF NOT EXISTS countries_geom_gix ON public.italy USING GIST(geom); 
CREATE INDEX IF NOT EXISTS oceans_geom_gix   ON public.oceans        USING GIST(geom); 

-- Country → Ocean (bounding-box + zero-gap)
DROP TABLE IF EXISTS public.ocean_country_edges;
CREATE TABLE public.ocean_country_edges AS
SELECT c.iso_a2                     AS source,
       o.name                       AS target,
       ST_Area(o.geom::geography)   AS cost
  FROM public.italy AS c
  JOIN public.oceans        AS o
    ON c.geom && o.geom              -- index-accelerated bbox test 
   AND ST_DWithin(c.geom, o.geom, 0)  -- bridge micro-gaps 
 WHERE c.iso_a2 ~ '^[A-Z]{2}$'
   AND o.name     IS NOT NULL;       -- filter out null names 

-- Mirror Ocean → Country
DROP TABLE IF EXISTS public.ocean_to_country_edges;
CREATE TABLE public.ocean_to_country_edges AS
SELECT target AS source, source AS target, cost
  FROM public.ocean_country_edges;

DROP TABLE IF EXISTS public.all_edges;
CREATE TABLE public.all_edges AS
  SELECT source, target, cost FROM country_edges
UNION ALL
  SELECT source, target, cost FROM public.ocean_country_edges
UNION ALL
  SELECT source, target, cost FROM public.ocean_to_country_edges;

CREATE INDEX ON public.all_edges(source);
CREATE INDEX ON public.all_edges(target);

DROP TABLE IF EXISTS exploration;
CREATE TEMP TABLE exploration (
  country    VARCHAR PRIMARY KEY,
  total_cost FLOAT,
  path       VARCHAR[]
);