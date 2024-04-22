# frozen_string_literal: true

desc 'One time data migration to populate custom assessment definition identifiers'
# rails driver:hmis:populate_assessment_definition_identifiers_20231121
task populate_assessment_definition_identifiers_20231121: [:environment] do
  # not running in a transaction custom assessments is fairly large, we expect the new relation to be null initially
  # so rollback would just be `Hmis::Hud::CustomAssessment.update_all(form_definition_identifier: nil)`

  # update the non-hud assessments
  # (also updates deleted records)
  Hmis::Hud::CustomAssessment.connection.execute <<~SQL
    UPDATE "CustomAssessments"
    SET "form_definition_identifier" = "hmis_form_definitions"."identifier"
    FROM "hmis_form_processors", "hmis_form_definitions"
    WHERE "hmis_form_processors"."custom_assessment_id" = "CustomAssessments"."id"
      AND "CustomAssessments"."form_definition_identifier" IS NULL
      AND "hmis_form_definitions"."id" = "hmis_form_processors"."definition_id"
  SQL

  # update hud assessments
  arel = Hmis::ArelHelper.instance
  data_source = GrdaWarehouse::DataSource.hmis.first!
  Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES.each do |role, stage|
    # This is expensive but needed as each project might have a different form definition for a given data collection stage
    # {intake => [project_id, ...]}
    project_ids_by_fd_identifier = {}
    Hmis::Hud::Project.where(data_source: data_source).group_by do |project|
      fd = Hmis::Form::Definition.find_definition_for_role(role, project: project)
      next unless fd

      project_ids_by_fd_identifier[fd.identifier] ||= []
      project_ids_by_fd_identifier[fd.identifier].push(project.project_id)
    end

    project_ids_by_fd_identifier.each do |fd_identifier, project_ids|
      assessment_scope = Hmis::Hud::CustomAssessment.with_deleted.
        joins(:enrollment).
        where(arel.e_t[:project_id].in(project_ids)).
        where(data_collection_stage: stage).
        where(form_definition_identifier: nil)
      assessment_scope.update_all(form_definition_identifier: fd_identifier)
    end
  end
end
