-- Semillas 100% ficticias de desarrollo y demostración para SéTú.
-- No contiene casos reales, identidad civil, credenciales reales ni contactos validados para operación.

-- ---------------------------------------------------------------------------
-- 1. Colegios ficticios (D1)
-- ---------------------------------------------------------------------------

INSERT INTO public.institutions (
  id,
  public_code,
  name,
  municipality,
  department,
  reference_lat,
  reference_lng,
  radius_meters,
  config_version,
  active
)
VALUES
  (
    '11111111-1111-4111-8111-000000000024',
    'AULA24',
    'Colegio Público Demo Centro América — CCE',
    'Managua',
    'Managua',
    12.098062,
    -86.2641465,
    150,
    1,
    true
  ),
  (
    '11111111-1111-4111-8111-000000000025',
    'AULA25',
    'Colegio Público Demo Sur — CCE',
    'Managua',
    'Managua',
    12.082500,
    -86.251200,
    150,
    1,
    true
  ),
  (
    '11111111-1111-4111-8111-000000000026',
    'AULA26',
    'Colegio Centro América',
    'Managua',
    'Managua',
    12.098062,
    -86.2641465,
    150,
    1,
    true
  )
ON CONFLICT (public_code) DO NOTHING;

-- Códigos privados de prueba únicamente para hash de demostración:
--   AULA24 -> 'DIR-AULA24-DEMO'
--   AULA25 -> 'DIR-AULA25-DEMO'
--   AULA26 -> 'DIR-AULA26-DEMO'
INSERT INTO public.institution_access_verifiers (
  institution_id,
  verifier_hash,
  label,
  active
)
SELECT
  v.institution_id,
  v.verifier_hash,
  v.label,
  true
FROM (
  VALUES
    (
      '11111111-1111-4111-8111-000000000024'::uuid,
      encode(sha256('DIR-AULA24-DEMO'::bytea), 'hex'),
      'Código privado demo AULA24'
    ),
    (
      '11111111-1111-4111-8111-000000000025'::uuid,
      encode(sha256('DIR-AULA25-DEMO'::bytea), 'hex'),
      'Código privado demo AULA25'
    ),
    (
      '11111111-1111-4111-8111-000000000026'::uuid,
      encode(sha256('DIR-AULA26-DEMO'::bytea), 'hex'),
      'Código privado demo AULA26'
    )
) AS v(institution_id, verifier_hash, label)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.institution_access_verifiers existing
  WHERE existing.institution_id = v.institution_id
    AND existing.verifier_hash = v.verifier_hash
);


-- ---------------------------------------------------------------------------
-- 2. Alta de personal solo con correos reales y funcionales (ADR 0020)
-- ---------------------------------------------------------------------------
-- Por decisión explícita del equipo, no se siembran cuentas ni invitaciones ficticias.
-- Para emitir la primera invitación administrativa MINED con un correo real:
--
--   SELECT private.issue_bootstrap_staff_invite(
--     p_institutional_email => 'coordinacion@tu-correo-real.org',
--     p_role                => 'mined_supervisor'::public.staff_role,
--     p_institution_id      => NULL,
--     p_staff_tier          => 'mined_central',
--     p_scope_label         => 'MINED central',
--     p_full_name           => 'Coordinación MINED'
--   );
--
-- Luego la persona crea su cuenta en SéTú (signUp), confirma el enlace recibido en su correo,
-- ingresa el código individual generado y completa su nombre y apellidos.
-- 3. Catálogo público D8 (Información ADR 0009 y líneas de ayuda)
-- ---------------------------------------------------------------------------

INSERT INTO public.editorial_resources (
  id,
  version,
  topic,
  format,
  title,
  summary,
  body_paragraphs,
  school_stage,
  duration_label,
  source_name,
  reviewer_name,
  verified_at,
  rights_notice,
  accessible_alternative,
  offline_packable,
  published
)
VALUES
  (
    'emociones',
    1,
    'Emociones',
    'guide',
    'Entendé tus emociones',
    'Qué son las emociones y cómo ponerles nombre.',
    '["Las emociones son señales del cuerpo y de la mente. Todas son válidas: nos avisan que algo nos importa.", "Ponerle nombre a lo que sentís —alegría, tristeza, enojo, miedo, sorpresa o calma— ayuda a que se sienta menos grande.", "Cuando una emoción pesa mucho, podés respirar despacio, contarle a alguien de confianza o pedir apoyo desde esta app."]'::jsonb,
    '3.º a 11.º grado',
    '3 min',
    'Equipo SéTú (muestra académica)',
    'Revisión clínica pendiente para piloto',
    '2026-11-12',
    'Material propio de demostración académica UAM - UNICEF 2026.',
    'Lectura completa disponible en texto sin conexión.',
    true,
    true
  ),
  (
    'convivencia',
    1,
    'Convivencia',
    'video',
    'Convivencia escolar',
    'Cómo construir un aula donde todas las personas se respeten.',
    '["Convivir bien no es no tener conflictos: es resolverlos sin humillar ni excluir a nadie.", "Si ves que molestan a alguien, acompañarle o avisar a una persona adulta de confianza también es ayudar. A eso le llamamos ser Testigo Solidario.", "Pedir apoyo no es acusar: es cuidar de vos y de tu grupo."]'::jsonb,
    '3.º a 11.º grado',
    '2 min',
    'Equipo SéTú (muestra académica)',
    'Revisión clínica pendiente para piloto',
    '2026-11-12',
    'Material propio de demostración académica UAM - UNICEF 2026.',
    'Resumen textual accesible mientras no haya video empaquetado.',
    true,
    true
  ),
  (
    'acoso-escolar',
    1,
    'Acoso escolar',
    'article',
    'Cuando las bromas dejan de ser bromas',
    'Señales para distinguir un conflicto pasajero del acoso escolar repetido.',
    '["No tenés que acostumbrarte a que te empujen, te insulten, te dejen fuera del grupo o compartan burlas sobre vos en redes.", "El acoso ocurre cuando el daño se repite y busca hacer sentir menos o aislar a una persona.", "Contarlo a tiempo permite que personas adultas capacitadas acompañen sin exponerte."]'::jsonb,
    '3.º a 11.º grado',
    '4 min',
    'Equipo SéTú (muestra académica)',
    'Revisión clínica pendiente para piloto',
    '2026-11-12',
    'Material propio de demostración académica UAM - UNICEF 2026.',
    'Artículo breve en español sencillo con lectura fuera de línea.',
    true,
    true
  ),
  (
    'pedir-apoyo',
    1,
    'Pedir apoyo',
    'testimony',
    'Hablar primero también cuesta, y ayuda',
    'Cómo dar el primer paso cuando no sabés con qué palabras empezar.',
    '["Muchas veces da miedo pensar que nadie va a creer lo que pasa o que la situación va a empeorar si alguien se entera.", "En SéTú podés empezar eligiendo solo el tipo de situación, sin tener que escribir todo desde el inicio.", "Si querés conversar, una persona real del equipo de escucha te responde cuando esté conectada."]'::jsonb,
    '3.º a 11.º grado',
    '3 min',
    'Equipo SéTú (testimonio editorial de muestra)',
    'Revisión clínica pendiente para piloto',
    '2026-11-12',
    'Testimonio editorial ficticio; no proviene de un caso privado real.',
    'Texto narrado disponible sin conexión.',
    true,
    true
  )
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.help_resources (
  id,
  name,
  phone_or_channel,
  territory,
  hours_label,
  source_name,
  editorial_responsible,
  verified_at,
  is_verified_for_pilot,
  display_order,
  published
)
VALUES
  (
    'mifan-133',
    'Línea 133 · MIFAN (orientación y protección a la niñez)',
    '133',
    'Nicaragua',
    'Horario y cobertura por confirmar antes del piloto',
    'Referencia de documentos del equipo (pendiente de verificación institucional)',
    'Equipo Bugñuelitos · Validación editorial pendiente',
    '2026-11-12',
    false,
    1,
    true
  ),
  (
    'policia-118',
    'Línea 118 · Policía Nacional (emergencias)',
    '118',
    'Nicaragua',
    'Atención de emergencias (verificar alcance territorial antes del piloto)',
    'Referencia de documentos del equipo (pendiente de verificación institucional)',
    'Equipo Bugñuelitos · Validación editorial pendiente',
    '2026-11-12',
    false,
    2,
    true

-- ---------------------------------------------------------------------------
-- 4. Nota sobre casos de prueba
-- ---------------------------------------------------------------------------
-- No se insertan casos asociados a cuentas ficticias.
-- Los casos de validación funcional se crean mediante submit_student_alert(...) con cuentas reales.
