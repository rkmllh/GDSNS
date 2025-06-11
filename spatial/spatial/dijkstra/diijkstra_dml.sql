UPDATE public.italy 
	SET iso_a2 = case name
		WHEN 'France' THEN 'FR'
		WHEN 'Norway' THEN 'NO'
		WHEN 'Kosovo' THEN 'XK'
 		ELSE iso_a2
	END
WHERE NAME IN ('France','Norway','Kosovo');