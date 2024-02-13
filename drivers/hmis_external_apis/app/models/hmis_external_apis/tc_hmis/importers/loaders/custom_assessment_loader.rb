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
      validate_cde_configs
      rows = reader.rows(filename: filename)
      clobber_records(rows) if clobber

      create_assessment_records(rows)
      create_form_processor_records(rows)

      create_cde_definitions

      # relies on custom assessments already built, associated by response_id
      create_cde_records(rows)
    end

    def runnable?
      # filename defined in subclass
      super && reader.file_present?(filename)
    end

    protected

    def validate_cde_configs
      seen_element_ids = Set.new

      required_keys = [:label, :key, :repeats, :field_type]
      all_keys = (required_keys + [:element_id]).to_set
      cded_configs.each do |item|
        # Check for required keys
        raise "Missing required keys in #{item.inspect}" unless required_keys.all? { |k| item.key?(k) }

        raise "Invalid keys present in #{item.inspect}" unless item.keys.all? { |k| all_keys.include?(k) }

        # If :element_id is present, check for uniqueness
        element_id = item[:element_id]
        next unless element_id
        raise "element_id must be integer in #{item.inspect}" unless element_id.is_a?(Integer)
        raise "Duplicate element_id: #{element_id}" if seen_element_ids.include?(element_id)

        seen_element_ids.add(element_id)
      end

      true # Return true if no exceptions were raised, indicating validation passed
    end

    def clobber_records(rows)
      assessment_ids = rows.map do |row|
        row_assessment_id(row)
      end
      assessment_ids.compact!

      scope = model_class.where(data_source_id: data_source.id).where(CustomAssessmentID: assessment_ids)
      scope.preload(:custom_data_elements).find_each do |assessment|
        assessment.custom_data_elements.delete_all # delete should really destroy
        assessment.really_destroy!
      end
      Hmis::Form::FormProcessor.where(custom_assessment_id: assessment_ids).delete_all
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
        next if enrollment_id.blank?

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

    # create synthetic form processors for imported touchpoints
    def create_form_processor_records(rows)
      owner_id_by_row_id = model_class.where(data_source: data_source).pluck(:CustomAssessmentID, :id).to_h
      processor_model = Hmis::Form::FormProcessor
      records = []
      rows.each do |row|
        assessment_id = owner_id_by_row_id[row_assessment_id(row)]
        next unless assessment_id

        records << {
          custom_assessment_id: assessment_id,
          definition_id: form_definition.id,
        }
      end
      ar_import(processor_model, records)
    end

    def create_cde_records(rows)
      owner_id_by_assessment_id = model_class.where(data_source: data_source).pluck(:CustomAssessmentID, :id).to_h

      seen = Set.new
      cdes = []
      rows.each do |row|
        owner_id = owner_id_by_assessment_id[row_assessment_id(row)]
        next unless owner_id

        cded_configs.each do |config|
          cde_values(row, config).each do |value|
            next if value.nil?

            key = config.fetch(:key)
            seen.add(key)
            cdes << cde_helper.new_cde_record(
              value: value,
              definition_key: key,
              owner_type: model_class.sti_name,
              owner_id: owner_id,
            )
          end
        end
      end
      ar_import(Hmis::Hud::CustomDataElement, cdes)

      total =  cded_configs.size
      missed = cded_configs.map { |c| c.fetch(:key) }.reject { |k| k.in?(seen) }
      log_info("saw CDE values for #{seen.size} of #{total} fields")
      log_info("missed CDE values for #{missed.size} of #{total} fields: #{missed.sort.join(', ')}") if missed.any?
    end

    def cde_values(row, config, required: false)
      id = config[:element_id]
      raw_value = id ? row.field_value_by_id(id, required: required) : row.field_value(config.fetch(:label), required: required)

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
