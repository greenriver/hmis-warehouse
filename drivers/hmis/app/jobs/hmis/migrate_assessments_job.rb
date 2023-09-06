###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class MigrateAssessmentsJob < BaseJob
    include Hmis::Concerns::HmisArelHelper
    include NotifierConfig

    attr_accessor :data_source_id

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    EXIT_STAGE = 3
    ENTRY_EXIT = [1, 3].freeze # entry, exit
    NON_ENTRY_EXIT = [2, 5, 6].freeze # update, annual, post-exit
    RELATED_RECORDS = [
      Hmis::Hud::IncomeBenefit,
      Hmis::Hud::HealthAndDv,
      Hmis::Hud::EmploymentEducation,
      Hmis::Hud::YouthEducationStatus,
      Hmis::Hud::Disability,
      Hmis::Hud::Exit,
    ].freeze

    def initialize
      setup_notifier('Migrate HMIS Assessments')
      super
    end

    # Construct CustomAssessment and FormProcessor records for Assessment-related records.
    #
    # For Entry/Exit assessments, records are grouped together if they have the same Data Collection Stage.
    # If information dates differ across records, the earliest one is chosen.
    #
    # For Update/Annual/PostExit assessments, records are grouped together if they have the same
    # Data Collection Stage AND information date.
    #
    # The resulting Assessments are constructed with:
    #  - DateCreated = earliest creation date of related records
    #  - DateUpdated = latest update date of related records
    #  - UserID = UserID from the related record that was most recently updated
    def perform(data_source_id:, clobber: false)
      self.data_source_id = data_source_id
      raise 'Not an HMIS Data source' if GrdaWarehouse::DataSource.find(data_source_id).hmis.nil?

      debug_log "Building assessments for data source #{data_source_id}"

      # Deletes the CustomAssessment and FormProcessor, but not the underlying data. It DOES delete Custom Data Elements tied to CustomAssessment.
      debug_log 'Deleting old assessments' if clobber
      Hmis::Hud::CustomAssessment.where(data_source_id: data_source_id).each(&:really_destroy!) if clobber

      Hmis::Hud::Enrollment.where(data_source_id: data_source_id).in_batches(of: 5_000) do |batch|
        # Build entry/exit assessments
        build_assessments(
          enrollment_scope: batch,
          data_collection_stages: ENTRY_EXIT,
          unique_by_information_date: false,
          data_source_id: data_source_id,
        )
        # Build other hud assessments
        build_assessments(
          enrollment_scope: batch,
          data_collection_stages: NON_ENTRY_EXIT,
          unique_by_information_date: true,
          data_source_id: data_source_id,
        )
      end

      summarize_assessments(data_source_id: data_source_id)
    end

    def build_assessments(enrollment_scope:, data_collection_stages:, unique_by_information_date:, data_source_id:)
      # Get "hash keys" for exiting assessments
      key_cols = [:enrollment_id, :personal_id, :data_collection_stage]
      key_cols << :assessment_date if unique_by_information_date
      keys_matching_existing_assessments = Hmis::Hud::CustomAssessment.joins(:enrollment).
        merge(enrollment_scope).
        pluck(*key_cols)

      # Key fields that will be used to group records
      key_fields = [:enrollment_id, :personal_id, :data_collection_stage]
      key_fields << :information_date if unique_by_information_date

      # Count of records that are skipped because they should already be tied to an assessment
      skipped_records = 0
      # Count of records that had duplicates. E.g. Two IncomeBenefit with same information date and data collection stage.
      duplicate_records = 0

      # Group together IDs of related records by key_fields
      assessment_records = {}

      RELATED_RECORDS.each do |klass|
        is_exit = klass == Hmis::Hud::Exit
        next if is_exit && !data_collection_stages.include?(EXIT_STAGE)

        group_by_fields = is_exit ? key_fields.take(2) : key_fields
        result_fields = [:id, :user_id, :date_created, :date_updated]
        result_fields << :information_date unless unique_by_information_date || is_exit
        result_fields << :disability_type if klass == Hmis::Hud::Disability
        result_fields << :exit_date if is_exit
        result_aggregations = result_fields.map { |f| nf('json_agg', [klass.arel_table[f]]).to_sql }

        scope = is_exit ? klass : klass.where(data_collection_stage: data_collection_stages)
        scope.joins(:enrollment).merge(enrollment_scope).
          group(*group_by_fields).
          pluck(*group_by_fields, *result_aggregations).
          each do |arr|
            # hash_key looks like ["502", "102", 1, Sun, 04 Jun 2023]
            hash_key = arr[0..group_by_fields.length - 1]
            hash_key << EXIT_STAGE if is_exit

            # values looks like {:id=>[6], :user_id=>["548"]}
            values = result_fields.zip(arr[group_by_fields.length..]).to_h

            if keys_matching_existing_assessments.include?(hash_key)
              # There is already a CustomAssessment record with this key, so skip the record
              skipped_records += 1
              next
            end

            # Choose oldest date_created and newest date_updated to apply to this hash_key
            metadata = merge_metadata(assessment_records[hash_key], values)

            case klass.name
            when 'Hmis::Hud::Disability'
              # Build hash like {:physical_disability_id=>25, :developmental_disability_id=>26, ...}
              colnames = values[:disability_type].map { |type| form_processor_column_name(klass, disability_type: type) }
              disability_ids = colnames.zip(values[:id]).to_h
              assessment_records.deep_merge!({ hash_key => { **disability_ids, **metadata } })
            else
              # Transform Hmis::Hud::HealthAndDv => health_and_dv_id
              colname = form_processor_column_name(klass)
              if values[:id].size > 1
                Rails.logger.info "More than 1 #{klass.name} for key. IDs: #{values[:id]}"
                duplicate_records += 1
              end
              record_id = values[:id].last
              assessment_records.deep_merge!({ hash_key => { colname => record_id, **metadata } })
            end
          end
      end

      debug_log "Skipped #{duplicate_records} duplicate records"
      debug_log "Skipped #{skipped_records} records that were already linked to an assessment"
      debug_log "Creating #{assessment_records.keys.size} assessments..."

      skipped_exit_assessments = 0
      # For each grouping of Enrollment+InformationDate+DataCollectionStage,
      # create a CustomAssessment and a FormProcessor that references the related records
      assessment_records.each do |hash_key, value|
        key = key_fields.zip(hash_key).to_h
        uniq_attributes = {
          data_source_id: data_source_id,
          assessment_date: key[:information_date], # if this is an Entry/Exit assmt, this will be nil
          **key.slice(:enrollment_id, :personal_id, :data_collection_stage),
        }.compact

        # Build CustomAssessment with appropriate metadata
        metadata_attributes = value.extract!(:user_id, :date_created, :date_updated, :assessment_date)
        assessment = Hmis::Hud::CustomAssessment.new(
          **uniq_attributes.merge(metadata_attributes),
          user: hud_users_by_id[metadata_attributes[:user_id]] || system_user,
          wip: false,
        )

        # Build FormProcessor with IDs to all related records
        assessment.build_form_processor(**value)

        if assessment.exit? && value[:exit_id].nil?
          # There appear to be lots of "exit" data-collection-stage records for enrollments that don't have an Exit record. Skip those
          Rails.logger.info "Skipping Exit Assessment for open enrollment. EnrollmentID: #{assessment.enrollment_id}"
          skipped_exit_assessments += 1
        else
          assessment.save!
        end
      end

      debug_log "Skipped creating #{skipped_exit_assessments} exit assessments because the enrollment is open"
    end

    private

    def system_user
      @system_user ||= Hmis::Hud::User.system_user(data_source_id: data_source_id)
    end

    def hud_users_by_id
      @hud_users_by_id ||= Hmis::Hud::User.where(data_source_id: data_source_id).index_by(&:user_id)
    end

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

    def merge_metadata(old_hash, values)
      metadata = old_hash&.slice(:user_id, :date_created, :date_updated, :assessment_date) || {}
      # Rename information_date and exit_date to assessment_date, these will be used to set assmt date (for Entry and Exit only)
      values[:assessment_date] = values.delete :information_date
      values[:assessment_date] = values.delete :exit_date if values.key?(:exit_date)

      new_metadata = values.slice(:user_id, :date_created, :date_updated, :assessment_date).compact.transform_values(&:first)

      # User that most recently updated
      user_latest_updated = [metadata, new_metadata].reject { |v| v[:date_updated].nil? || v[:user_id].nil? }.
        select { |v| hud_users_by_id.key?(v[:user_id]) }. # keep if we have this user record
        max_by { |v| v[:date_updated].to_datetime }&.fetch(:user_id)

      metadata.merge(new_metadata) do |key, oldval, newval|
        case key
        when :date_created
          [oldval, newval].compact.map(&:to_datetime).min
        when :date_updated
          [oldval, newval].compact.map(&:to_datetime).max
        when :assessment_date
          [oldval, newval].compact.map(&:to_datetime).min
        when :user_id
          user_latest_updated
        else
          [oldval, newval].compact.first
        end
      end
    end

    def summarize(numer, denom, msg: nil)
      pct = if denom.positive?
        ((numer.to_f / denom) * 100).to_i
      else
        0
      end

      "#{pct}% #{msg} (#{numer}/#{denom})"
    end

    def summarize_assessments(data_source_id:)
      enrollment_scope = Hmis::Hud::Enrollment.where(data_source_id: data_source_id)
      assessment_scope = Hmis::Hud::CustomAssessment.where(data_source_id: data_source_id)

      open_enrollment_assessment_scope = Hmis::Hud::CustomAssessment.joins(:enrollment).merge(enrollment_scope.open_on_date)

      num_enrollments = enrollment_scope.size
      num_open_enrollments = enrollment_scope.open_on_date.size
      num_exited_enrollments = enrollment_scope.exited.size

      msgs = []
      msgs << summarize(assessment_scope.intakes.size, num_enrollments, msg: 'of enrollments have intake assessments')
      msgs << summarize(open_enrollment_assessment_scope.intakes.size, num_open_enrollments, msg: 'of open enrollments have intake assessments')
      msgs << summarize(assessment_scope.exits.size, num_exited_enrollments, msg: 'of exited enrollments have exit assessments')
      msgs << summarize(open_enrollment_assessment_scope.exits.size, num_open_enrollments, msg: 'of open enrollments have exit assessments')
      msgs << summarize(assessment_scope.annuals.size, num_enrollments, msg: 'of enrollments have annual assessments')
      msgs << summarize(assessment_scope.updates.size, num_enrollments, msg: 'of enrollments have update assessments')
      debug_log(msgs.join("\n"))
    end

    def debug_log(message)
      @notifier&.ping(message)
    end
  end
end
