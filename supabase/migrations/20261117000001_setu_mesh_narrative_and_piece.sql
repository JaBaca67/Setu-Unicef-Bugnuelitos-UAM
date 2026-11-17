-- Solo demo ficticia. ADR 0028 (17 nov 2026): las alertas que llegan por red
-- mesh pueden traer el relato breve y la pieza simbólica del estudiante.
-- Viajan dentro del sobre cifrado de extremo a extremo, sellado para personal
-- autorizado; los teléfonos intermedios no pueden leerlos. Siguen prohibidos
-- por mesh el lugar y la fecha aproximada (la app no los envía por ese canal).
--
-- Las cuatro versiones de `submit_student_alert` (públicas y privadas) tenían
-- la misma guarda `mesh_origin_cannot_carry_narrative`. Se reescribe solo esa
-- condición sobre la definición vigente para no duplicar cuerpos largos.
DO $migration$
DECLARE
  r record;
  v_def text;
  v_new text;
BEGIN
  FOR r IN
    SELECT p.oid
    FROM pg_catalog.pg_proc p
    WHERE p.proname = 'submit_student_alert'
      AND pg_catalog.pg_get_functiondef(p.oid) LIKE '%mesh_origin_cannot_carry_narrative%'
  LOOP
    v_def := pg_catalog.pg_get_functiondef(r.oid);
    -- Variante con variables locales (v_narrative / v_location / v_approx_date).
    v_new := regexp_replace(
      v_def,
      'v_narrative IS NOT NULL\s*OR pg_catalog\.char_length\(v_location\) > 0',
      'pg_catalog.char_length(v_location) > 0'
    );
    -- Variante con parámetros (p_narrative_text / p_student_piece).
    v_new := regexp_replace(
      v_new,
      'NULLIF\(btrim\(COALESCE\(p_narrative_text, ''''\)\), ''''\) IS NOT NULL\s*OR NULLIF\(btrim\(COALESCE\(p_location_text',
      'NULLIF(btrim(COALESCE(p_location_text'
    );
    v_new := regexp_replace(v_new, '\s*OR p_student_piece IS NOT NULL\)', ')');
    IF v_new = v_def THEN
      RAISE EXCEPTION 'mesh_narrative_patch_not_applied for %', r.oid::regprocedure;
    END IF;
    EXECUTE v_new;
  END LOOP;
END
$migration$;
