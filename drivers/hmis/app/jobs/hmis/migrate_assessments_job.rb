###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class MigrateAssessmentsJob < ApplicationJob
    include Hmis::Concerns::HmisArelHelper

    # Construct CustomAssessment and FormProcessor records for Assessment-related records.
    # Records considered to be sourced from the same assessment if they share an Information date
    # and Data Collection Stage.
    #
    # This mostly ASSUMES that the data quality is perfect. If data is bad, it will created bad assessments.
    # For example:
    # * Exit Date should match the Information Date for other records collected at Exit.
    # * There should be only 1 group of records collected at Entry, all with the same Information date
    # * There should be only 1 group of records collected at Exit, all with the same Information date
    def perform(data_source_id:)
      system_user = Hmis::Hud::User.system_user(data_source_id: data_source_id)
      scope = Hmis::Hud::Enrollment.where(data_source_id: data_source_id)

      key_fields = [:enrollment_id, :personal_id, :data_collection_stage, :information_date]

      scope.in_batches(of: 5_000) do |enrollment_batch|
        # Build scope of assessments that already exist for this set of enrollments
        keys_matching_existing_assessments = Hmis::Hud::CustomAssessment.joins(:enrollment).
          merge(enrollment_batch).
          pluck(:enrollment_id, :personal_id, :data_collection_stage, :assessment_date)

        # Count of records that are skipped because they should already be tied to an assessment
        skipped_records = 0

        # Group together IDs of related records by key_fields
        assessment_records = {}
        [
          Hmis::Hud::IncomeBenefit,
          Hmis::Hud::HealthAndDv,
          Hmis::Hud::EmploymentEducation,
          Hmis::Hud::YouthEducationStatus,
          Hmis::Hud::EnrollmentCoc,
          Hmis::Hud::Disability,
          Hmis::Hud::Exit,
        ].each do |klass|
          group_by_fields = klass == Hmis::Hud::Exit ? key_fields.take(2) : key_fields

          result_fields = [:id, :user_id]
          result_fields << :disability_type if klass == Hmis::Hud::Disability
          result_fields << :exit_date if klass == Hmis::Hud::Exit

          result_aggregations = result_fields.map { |f| nf('json_agg', [klass.arel_table[f]]).to_sql }

          klass.joins(:enrollment).merge(enrollment_batch).
            group(*group_by_fields).
            pluck(*group_by_fields, *result_aggregations).
            each do |arr|
              # hash_key looks like ["502", "102", 1, Sun, 04 Jun 2023]
              hash_key = arr[0..group_by_fields.length - 1]
              # values looks like {:id=>[6], :user_id=>["548"]}
              values = result_fields.zip(arr[group_by_fields.length..]).to_h
              hash_key += [3, Date.parse(values[:exit_date].last)] if klass == Hmis::Hud::Exit

              if keys_matching_existing_assessments.include?(hash_key)
                # There is already a CustomAssessment record with this key, so skip the record
                skipped_records += 1
                next
              end

              user_id = values[:user_id].last

              case klass.name
              when 'Hmis::Hud::Disability'
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

        puts "Skipped #{skipped_records} records. Creating #{assessment_records.keys.size} assessments..."

        # For each grouping of Enrollment+InformationDate+DataCollectionStage,
        # create a CustomAssessment and a FormProcessor that references the related records
        assessment_records.each do |hash_key, value|
          key = key_fields.zip(hash_key).to_h
          uniq_attributes = {
            data_source_id: data_source_id,
            assessment_date: key[:information_date],
            **key.slice(:enrollment_id, :personal_id, :data_collection_stage),
          }

          assessment = Hmis::Hud::CustomAssessment.new(
            **uniq_attributes,
            user_id: value[:user_id] || system_user.user_id,
          )
          assessment.build_form_processor(**value.except(:user_id))
          assessment.save!
        end
      end
    end

    private

    # Map class name to column name on form process0r
    def form_processor_column_name(klass, disability_type: nil)
      return "#{klass.name.demodulize.underscore}_id".to_sym unless klass == Hmis::Hud::Disability

      raise 'disability record without disability type' unless disability_type.present?

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
