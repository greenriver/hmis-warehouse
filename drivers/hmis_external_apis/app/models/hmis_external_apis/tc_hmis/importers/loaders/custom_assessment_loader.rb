###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

#  Abstract class
module HmisExternalApis::TcHmis::Importers::Loaders
  class CustomAssessmentLoader < BaseLoader
    ENROLLMENT_ID_COL = 'Unique Enrollment Identifier'.freeze
    RESPONSE_ID_COL = 'Response ID'.freeze

    def perform
      rows = reader.rows(filename: filename)
      clobber_records(rows) if clobber

      create_assessment_records(rows)

      create_cde_definitions

      # relies on custom assessments already built, associated by response_id
      create_cde_records(rows)
    end

    def runnable?
      # filename defined in subclass
      super && reader.file_present?(filename)
    end

    protected

    def clobber_records(rows)
      assessment_ids = rows.map do |row|
        row_assessment_id(row)
      end

      scope = model_class.where(data_source_id: data_source.id).where(CustomAssessmentID: assessment_ids)
      scope.preload(:custom_data_elements).find_each do |assessment|
        assessment.custom_data_elements.delete_all # delete should really destroy
        assessment.really_destroy!
      end
    end

    def create_cde_definitions
      cded_configs.each do |config|
        cde_helper.find_or_create_cded(
          **config.merge(owner_type: model_class.sti_name).except(:element_id),
        )
      end
    end

    def create_assessment_records(rows)
      personal_id_by_enrollment_id = Hmis::Hud::Enrollment.
        where(data_source: data_source).
        pluck(:enrollment_id, :personal_id).
        to_h

      expected = 0
      actual = 0
      records = rows.flat_map do |row|
        expected += 1
        enrollment_id = row.field_value(ENROLLMENT_ID_COL)
        # enrollment_id = personal_id_by_enrollment_id.keys.first
        personal_id = personal_id_by_enrollment_id[enrollment_id]

        if personal_id.nil?
          log_skipped_row(row, field: ENROLLMENT_ID_COL)
          next # early return
        end
        actual += 1

        {
          data_source_id: data_source.id,
          CustomAssessmentID: row_assessment_id(row),
          EnrollmentID: enrollment_id,
          PersonalID: personal_id,
          UserID: system_hud_user.id,
          AssessmentDate: row_assessment_date(row),
          DataCollectionStage: 2,
          wip: false,
          DateCreated: today,
          DateUpdated: today,
        }
      end
      log_processed_result(expected: expected, actual: actual)
      ar_import(model_class, records)
    end

    def create_cde_records(rows)
      owner_id_by_assessment_id = model_class.where(data_source: data_source).pluck(:CustomAssessmentID, :id).to_h

      cdes = []
      rows.each do |row|
        owner_id = owner_id_by_assessment_id[row_assessment_id(row)]
        raise unless owner_id

        cded_configs.each do |config|
          cde_values(row, config).each do |value|
            cdes << cde_helper.new_cde_record(
              value: value,
              definition_key: config.fetch(:key),
              owner_type: model_class.sti_name,
              owner_id: owner_id,
            )
          end
        end
      end
      ar_import(Hmis::Hud::CustomDataElement, cdes)
    end

    def cde_values(row, config, required: false)
      raw_value = row.field_value(config.fetch(:label), id: config[:element_id], required: required)
      return [] unless raw_value

      values = config.fetch(:repeats) ? raw_value.split('|').map(&:strip) : [raw_value]
      field_type = config.fetch(:field_type)
      values.compact_blank.map do |value|
        case field_type
        when 'string'
          value
        when 'integer'
          value.to_i
        when 'boolean'
          yn_boolean(value)
        when 'date'
          parse_date(value)
        else
          raise "field_type #{field_type} not support on key #{config.fetch(:key)}"
        end
      end
    end

    def model_class
      Hmis::Hud::CustomAssessment
    end
  end
end
