###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class MigrateAssessmentsJob < ApplicationJob
    include Hmis::Concerns::HmisArelHelper

    def perform(data_source_id:)
      system_user = Hmis::Hud::User.system_user(data_source_id: data_source_id)
      scope = Hmis::Hud::Enrollment.where(data_source_id: data_source_id)

      key_fields = [
        :enrollment_id,
        :personal_id,
        :data_collection_stage,
        :information_date,
      ]

      scope.in_batches(of: 1_000) do |enrollment_batch|
        # Group together IDs of related records by key_fields
        assessment_records = {}
        [
          Hmis::Hud::IncomeBenefit,
          Hmis::Hud::HealthAndDv,
          Hmis::Hud::EmploymentEducation,
          Hmis::Hud::YouthEducationStatus,
          Hmis::Hud::Disability,
        ].each do |klass|
          result_fields = [:id, :user_id]
          result_fields << :disability_type if klass == Hmis::Hud::Disability

          result_aggregations = result_fields.map { |f| nf('json_agg', [klass.arel_table[f]]).to_sql }

          klass.joins(:enrollment).merge(enrollment_batch).
            group(*key_fields).
            pluck(*key_fields, *result_aggregations).
            each do |arr|
              hash_key = arr[0..key_fields.length - 1] # ["502", "102", 1, Sun, 04 Jun 2023]
              values = result_fields.zip(arr[key_fields.length..]).to_h # {:id=>[6], :user_id=>["548"]}
              user_id = values[:user_id].last

              if klass == Hmis::Hud::Disability
                # Build hash like {:physical_disability_id=>25, :developmental_disability_id=>26, ...}
                colnames = values[:disability_type].map { |type| form_processor_column_name(klass, disability_type: type) }
                disability_ids = colnames.zip(values[:id]).to_h
                assessment_records.deep_merge!({ hash_key => { user_id: user_id, **disability_ids } })
              else
                # Transform Hmis::Hud::HealthAndDv => health_and_dv_id
                colname = form_processor_column_name(klass)
                record_id = values[:id].last
                puts "WARNING: more than 1 #{klass.name} for key. IDs: #{values[:id]}" if values[:id].size > 1
                assessment_records.deep_merge!({ hash_key => { user_id: user_id, colname => record_id } })
              end
            end
        end

        # TODO add Exits (and EnrollmentCoCs...) which are not based on DCS/IDate

        existing_assessment_scope = Hmis::Hud::CustomAssessment.joins(:enrollment).merge(enrollment_batch)

        # For each grouping of Enrollment+InformationDate+DataCollectionStage,
        # create a CustomAssessment and a FormProcessor that references the related records
        assessment_records.each do |hash_key, value|
          key = key_fields.zip(hash_key).to_h
          uniq_attributes = {
            data_source_id: data_source_id,
            assessment_date: key[:information_date],
            **key.slice(:enrollment_id, :personal_id, :data_collection_stage),
          }
          next if existing_assessment_scope.where(**uniq_attributes).exists?

          assessment = Hmis::Hud::CustomAssessment.new(
            **uniq_attributes,
            user_id: value[:user_id] || system_user.user_id,
          )
          assessment.build_form_processor(**value.except(:user_id))
          assessment.save!
        end
      end
    end

    # Map class name to column name on form processir
    def form_processor_column_name(klass, disability_type: nil)
      return "#{klass.name.demodulize.underscore}_id".to_sym unless klass == Hmis::Hud::Disability

      case disability_type
      when 5
        :physical_disability_id
      when 6
        :developmental_disability_id
      when 7
        :chronic_health_condition_id
      when 8
        :hiv_aids_id
      when 9
        :mental_health_disorder_id
      when 10
        :substance_use_disorder_id
      else
        raise "Disability type not found: #{disability_type}"
      end
    end
  end
end
