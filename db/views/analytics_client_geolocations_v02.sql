SELECT
    clh_locations.id,
    -- for HMIS-collected locations, client_id is the source client's id.
    -- for Warehouse locations that were imported from external sources, client_id is the destination client's id
    clh_locations.client_id,
    -- for HMIS-collected locations, source_type is always "GrdaWarehouse::Hud::Enrollment"
    clh_locations.source_type,
    clh_locations.source_id,
    clh_locations.located_on,
    clh_locations.lat,
    clh_locations.lon,
    -- For HMIS-collected Locations collected_by gets filled as the Project Name. However they are tied to an Enrollment via source_id/source_type`, so the project name is redundant
    -- clh_locations.collected_by,
    -- clh_locations.processed_at,
    clh_locations.created_at,
    clh_locations.updated_at,
    -- legacy field
    -- clh_locations.enrollment_id,
    clh_locations.located_at,

    -- If location was collected via an HMIS form, id of the form definition
    hmis_form_processors.definition_id as form_definition_id,
    -- If location was collected via HMIS form, type of the associated record
    -- (eg "HmisExternalApis::ExternalForms::FormSubmission", "Hmis::Hud::CustomAssessment" or "Hmis::Hud::CurrentLivingSituation")
    hmis_form_processors.owner_type,
    hmis_form_processors.owner_id -- ID of associated record

FROM
    public.clh_locations
LEFT OUTER JOIN public.hmis_form_processors
    ON hmis_form_processors.clh_location_id = clh_locations.id
WHERE
    clh_locations.deleted_at IS NULL AND clh_locations.lat IS NOT NULL AND clh_locations.lon IS NOT NULL;
