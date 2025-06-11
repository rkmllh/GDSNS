DO $$
DECLARE
  curr_country VARCHAR;
  curr_cost    DOUBLE PRECISION;
  curr_path    TEXT[];
  nbr           RECORD;
BEGIN
  -- Initialize with Italy
  INSERT INTO exploration(country, total_cost, path)
    VALUES ('IT', 0, ARRAY['IT'])
  ON CONFLICT (country) DO NOTHING;

  LOOP

    SELECT country, total_cost, path
      INTO curr_country, curr_cost, curr_path
    FROM exploration
    ORDER BY total_cost
    LIMIT 1;

    -- Go out if no node remains
    IF NOT FOUND THEN
      RAISE NOTICE 'Frontier empty — terminating';
      EXIT;
    END IF;

    -- Just for debugging, ignore
    RAISE NOTICE 'Exploring: %, Cost: %, Path: %',
                 curr_country, curr_cost, curr_path;

    -- Early-exit if destination reached
	-- Please note this is different from Dijkstra alg
    IF curr_country = 'AR' THEN        -- target! Final destination!
      RAISE NOTICE 'Reached % — done', curr_country;
      EXIT;
    END IF;

    -- Expand neighbors, rememeber to skip any yet in curr_path to avoid cycles
    FOR nbr IN
      SELECT
        e.target,
        curr_cost + e.cost    AS new_cost,
        curr_path || e.target AS new_path
      FROM public.all_edges AS e
      WHERE e.source = curr_country
        AND e.target IS NOT NULL
        AND e.target <> ALL(curr_path)    -- **cycle prevention** 
    LOOP
      -- If the neighbor exists with a higher cost, we update it
      UPDATE exploration
      SET total_cost = nbr.new_cost,
          path       = nbr.new_path
      WHERE country = nbr.target
        AND nbr.new_cost < total_cost;

      -- Otherwise, insert it; do nothing on conflict
      INSERT INTO exploration(country, total_cost, path)
      VALUES (nbr.target, nbr.new_cost, nbr.new_path)
      ON CONFLICT (country) DO NOTHING;
    END LOOP;

    -- Mark current as visited
    DELETE FROM exploration WHERE country = curr_country;
  END LOOP;
END
$$ LANGUAGE plpgsql;

SELECT path, total_cost
  FROM exploration
 WHERE country = 'AR';   -- or 'AR' for Argentina

--SELECT * FROM all_edges;
--SELECT name, iso_a2 FROM italy;