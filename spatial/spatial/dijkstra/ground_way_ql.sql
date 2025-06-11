DO $$
DECLARE
  curr_country VARCHAR;
  curr_cost    DOUBLE PRECISION;
  curr_path    TEXT[];
  nbr           RECORD;
BEGIN

  INSERT INTO exploration(country, total_cost, path)
  VALUES ('IT', 0, ARRAY['IT'])
  ON CONFLICT (country) DO NOTHING;

  LOOP

    SELECT country, total_cost, path
      INTO curr_country, curr_cost, curr_path
    FROM exploration
    ORDER BY total_cost
    LIMIT 1;

    EXIT WHEN curr_country = 'ES';

    FOR nbr IN
      SELECT
        target,
        curr_cost + cost    AS new_cost,
        curr_path || target AS new_path
      FROM country_edges
      WHERE source = curr_country
    LOOP

      UPDATE exploration
      SET total_cost = nbr.new_cost,
          path       = nbr.new_path
      WHERE country = nbr.target
        AND nbr.new_cost < total_cost;

      INSERT INTO exploration(country, total_cost, path)
      VALUES (nbr.target, nbr.new_cost, nbr.new_path)
      ON CONFLICT (country) DO NOTHING;
    END LOOP;

    DELETE FROM exploration
    WHERE country = curr_country;
  END LOOP;
END
$$ LANGUAGE plpgsql;

-- Print original countries, not iso_code!
SELECT
  array_agg(ci.name ORDER BY p.ord) AS path_names,
  e.total_cost
FROM exploration e
JOIN LATERAL (
  SELECT code, ord
  FROM unnest(e.path) WITH ORDINALITY AS t(code, ord)
) AS p ON TRUE
LEFT JOIN country_info ci 
  ON ci.country_code = p.code
WHERE e.country = 'ES'
GROUP BY e.total_cost;

--select name, iso_a2 from italy;

--SELECT * FROM country_edges;