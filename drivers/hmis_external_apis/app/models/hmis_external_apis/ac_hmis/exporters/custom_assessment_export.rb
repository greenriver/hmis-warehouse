###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis::Exporters
  class CustomAssessmentExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter

    def run!
      Rails.logger.info 'Generating content of custom assessment export'

      write_row(columns)
      total = custom_assessments.count

      custom_assessments.find_each.with_index do |custom_assessment, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 1_000).zero?

        warehouse_id = custom_assessment.client&.warehouse_id
        next unless warehouse_id.present? # Client doesn't have a destination client ID yet. Skip since it wont be in Client.csv anyway.

        form_definition = custom_assessment.definition
        raise 'assessment missing form definition' unless form_definition

        hud_user_id = custom_assessment.user&.id

        values = [
          custom_assessment.id,
          custom_assessment.enrollment.id,
          warehouse_id,
          custom_assessment.assessment_date,
          form_definition.identifier,
          form_definition.title,
          custom_assessment.date_created,
          custom_assessment.date_updated,
          # prefer to use the created/updated columns, otherwise use UserID column
          custom_assessment.created_by_hud_user_id || hud_user_id, # maps to User.csv in HMIS CSV Export
          custom_assessment.updated_by_hud_user_id || hud_user_id, # maps to User.csv in HMIS CSV Export
        ]
        write_row(values)
      end
    end

    def columns
      [
        'CustomAssessmentID', # Maps to RecordId in CustomFieldValues.csv
        'EnrollmentID',       # EnrollmentID matching Enrollment.csv in HMIS CSV export (database id)
        'PersonalID',         # PersonalID matching Client.csv in HMIS CSV export (warehouse destination id)
        'AssessmentDate',     # Assessment Date collected on the assessment
        'AssessmentKey',      # Stable key identifying the type of assessment
        'AssessmentTitle',    # Title of the assessment
        'DateCreated',        # Timestamp when the assessment was created
        'DateUpdated',        # Timestamp when the assessment was last updated
        'CreatedByUserID',    # Maps to User.csv
        'UpdatedByUserID',    # Maps to User.csv
      ]
    end

    private

    def custom_assessments
      Hmis::Hud::CustomAssessment.where(data_source: data_source).not_in_progress.
        with_role(:CUSTOM_ASSESSMENT).
        joins(:enrollment).
        merge(Hmis::Hud::Enrollment.not_in_progress). # drop WIP Enrollments, which won't be present in Enrollment.csv export
        preload(
          :definition, # to get form name
          :enrollment, # to get db id
          :user, # to get user
          client: :warehouse_client_source, # to get destination id
        ).
        distinct
    end
  end
end
