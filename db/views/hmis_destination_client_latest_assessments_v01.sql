-- View that provides latest custom assessments for destination clients
-- This enables easy joining to get CDE values from the most recent assessments per form type
SELECT DISTINCT ON (wc.destination_id, def.identifier)
  wc.destination_id AS destination_client_id,
  ca.id AS custom_assessment_id,
  def.identifier AS form_identifier
FROM "warehouse_clients" wc
INNER JOIN "Client" c ON c."DateDeleted" IS NULL
  AND c.id = wc.source_id
INNER JOIN "CustomAssessments" ca ON ca."DateDeleted" IS NULL
  AND ca."data_source_id" = c."data_source_id"
  AND ca."PersonalID" = c."PersonalID"
INNER JOIN "hmis_form_processors" fp ON fp.owner_type = 'Hmis::Hud::CustomAssessment'
  AND fp.owner_id = ca.id
INNER JOIN "hmis_form_definitions" def ON def."deleted_at" IS NULL
  AND def.id = fp.definition_id
WHERE wc.destination_id IS NOT NULL
ORDER BY wc.destination_id, def.identifier, ca."DateUpdated" DESC, ca.id DESC;
