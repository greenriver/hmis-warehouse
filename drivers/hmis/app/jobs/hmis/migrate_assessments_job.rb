###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# == Hmis::MigrateAssessmentsJob
#
# Intended to be run manually during the setup and migration phase of a new HMIS installation
#
module Hmis
  class MigrateAssessmentsJob < BaseJob
    include Hmis::Concerns::HmisArelHelper
    include NotifierConfig

    # TODO(maybe): Add option to create Exit Assessment if there are Exit-stage records, even if there is no Exit record. Enrollment would remain open but the exit assessment would exist. This could have other unintended side effects.
    attr_accessor :data_source_id, :soft_delete_datetime, :delete_dangling_records, :preferred_source_hash, :project_ids, :generate_empty_intakes

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

    # Construct CustomAssessment and FormProcessor records for Assessment-related records.
    # Can be run for an entire data source or for a set of projects.
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
    def perform(data_source_id:, project_ids: nil, clobber: false, delete_dangling_records: false, preferred_source_hash: nil, generate_empty_intakes: false)
      setup_notifier('Migrate HMIS Assessments')

      self.data_source_id = data_source_id
      self.project_ids = Array.wrap(project_ids)
      self.soft_delete_datetime = Time.current
      self.delete_dangling_records = delete_dangling_records
      self.preferred_source_hash = preferred_source_hash
      self.generate_empty_intakes = generate_empty_intakes
      raise 'Not an HMIS Data source' if ::GrdaWarehouse::DataSource.find(data_source_id).hmis.nil?

      debug_log "MigrateAssessmentsJob starting at #{Time.current.to_fs(:db)}"

      # Deletes the CustomAssessment and FormProcessor, but not the underlying data. It DOES delete Custom Data Elements tied to CustomAssessment.
      if clobber
        Hmis::Hud::CustomAssessment.
          joins(:project).merge(project_scope).
          where(data_collection_stage: HudUtility2024.data_collection_stages.keys). # Only clobber HUD assessments, not fully custom assessments
          each(&:really_destroy!)
      end

      total = full_enrollment_scope.count
      Rails.logger.info "#{total} Enrollments to process"

      full_enrollment_scope.in_batches(of: 5_000) do |batch|
        # Build entry/exit assessments
        build_assessments(
          enrollment_batch: batch,
          data_collection_stages: ENTRY_EXIT,
          unique_by_information_date: false,
          data_source_id: data_source_id,
        )

        # Build other hud assessments
        build_assessments(
          enrollment_batch: batch,
          data_collection_stages: NON_ENTRY_EXIT,
          unique_by_information_date: true,
          data_source_id: data_source_id,
        )
      end

      # Delete any records that were marked for deletion
      if delete_dangling_records
        debug_log("Deleting dangling records:\n #{records_to_delete.map { |k, ids| [k.name, ids.size] }.to_h}")
        records_to_delete.each do |klass, ids|
          klass.where(id: ids).update_all(DateDeleted: soft_delete_datetime, source_hash: nil)
        end
      end

      debug_log "MigrateAssessmentsJob completed at #{Time.current.to_fs(:db)}"
      log_assessment_summary
    end

    def records_to_delete
      @records_to_delete ||= {}
    end

    def mark_for_deletion(klass, ids)
      records_to_delete[klass] ||= []
      records_to_delete[klass].concat(ids)
    end

    def full_enrollment_scope
      # Note: joining with project drops WIP enrollments. That should be fine since they won't have assessment records yet.
      @full_enrollment_scope ||= Hmis::Hud::Enrollment.joins(:project).merge(project_scope)
    end

    def build_assessments(enrollment_batch:, data_collection_stages:, unique_by_information_date:, data_source_id:)
      # Get "hash keys" for exiting assessments
      key_cols = [:enrollment_id, :personal_id, :data_collection_stage]
      key_cols << :assessment_date if unique_by_information_date
      keys_matching_existing_assessments = Hmis::Hud::CustomAssessment.joins(:enrollment).
        merge(enrollment_batch).
        pluck(*key_cols)

      # Key fields that will be used to group records
      key_fields = [:enrollment_id, :personal_id, :data_collection_stage]
      key_fields << :information_date if unique_by_information_date

      # EnrollmentIDs of exited enrollments
      exited_enrollment_ids = enrollment_batch.joins(:exit).pluck(:enrollment_id).to_set

      # Count of records that are skipped because they should already be tied to an assessment
      skipped_records = 0

      # Group together IDs of related records by key_fields
      assessment_records = {}

      RELATED_RECORDS.each do |klass|
        is_exit = klass == Hmis::Hud::Exit
        next if is_exit && !data_collection_stages.include?(EXIT_STAGE)

        group_by_fields = is_exit ? key_fields.take(2) : key_fields
        result_fields = [:id, :user_id, :date_created, :date_updated, :source_hash]
        result_fields << :information_date unless unique_by_information_date || is_exit
        result_fields << :disability_type if klass == Hmis::Hud::Disability
        result_fields << :exit_date if is_exit
        result_aggregations = result_fields.map { |f| nf('json_agg', [klass.arel_table[f]]).to_sql }

        scope = is_exit ? klass : klass.where(data_collection_stage: data_collection_stages)
        scope.joins(:enrollment).merge(enrollment_batch).
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

            enrollment_id, _personal_id, data_collection_stage = hash_key
            # If records have DataCollectionStage of Exit, but this enrollment is open, skip and mark for deletion.
            if data_collection_stage == EXIT_STAGE && !exited_enrollment_ids.include?(enrollment_id)
              Rails.logger.info "Found #{klass.name} record with Data Collection Stage 'Exit' for an open enrollment. EnrollmentID #{enrollment_id}, record ID(s): #{values[:id]}"
              mark_for_deletion(klass, values[:id])
              next
            end

            case klass.name
            when 'Hmis::Hud::Disability'
              # Build hash like {:physical_disability_id=>25, :developmental_disability_id=>26, ...}
              colnames = values[:disability_type].map { |type| form_processor_column_name(klass, disability_type: type) }
              disability_ids = colnames.zip(values[:id]).to_h
              # Choose oldest date_created and newest date_updated to apply to this hash_key
              metadata = merge_metadata(assessment_records[hash_key], values)
              assessment_records.deep_merge!({ hash_key => { **disability_ids, **metadata } })
            else
              # If there were multiple records matching this key, choose 1
              values_without_dups = remove_duplicates(values, klass)
              record_id = values_without_dups[:id].first

              # Base metadata off of the chosen record, not any of the duplicates
              metadata = merge_metadata(assessment_records[hash_key], values_without_dups)
              # Transform Hmis::Hud::HealthAndDv => health_and_dv_id
              colname = form_processor_column_name(klass)
              assessment_records.deep_merge!({ hash_key => { colname => record_id, **metadata } })
            end
          end
      end

      deletion_count = records_to_delete.values.flatten.size
      Rails.logger.info "Marking #{deletion_count} records for deletion" if deletion_count.positive?
      Rails.logger.info "Skipped #{skipped_records} records that were already linked to an assessment" if skipped_records.positive?
      Rails.logger.info "Creating #{assessment_records.keys.size} assessments..."

      skipped_invalid_assessments = 0
      skipped_exit_assessments = 0
      skipped_intake_enrollment_ids = []

      # For each grouping of Enrollment+InformationDate+DataCollectionStage,
      # create a CustomAssessment and a FormProcessor that references the related records
      assessments_to_import = []
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

        if !assessment.valid?
          # This check was added because we hit a "Client is invalid", which may have occurred if the client was deleted while the batch was processing?
          Rails.logger.info "Skipping invalid assessment for EnrollmentID: #{assessment.enrollment_id}"
          skipped_invalid_assessments += 1
          skipped_intake_enrollment_ids << assessment.enrollment_id if assessment.intake?
        elsif assessment.exit? && value[:exit_id].nil?
          # There appear to be lots of "exit" data-collection-stage records for enrollments that don't have an Exit record.
          # This shouldn't happen anymore because we skip them above
          Rails.logger.info "Skipping Exit Assessment for open enrollment. EnrollmentID: #{assessment.enrollment_id}"
          skipped_exit_assessments += 1
        else
          assessments_to_import << assessment
        end
      end

      Rails.logger.info "Importing #{assessments_to_import.size} assessments..."
      ar_import(assessments_to_import)

      Rails.logger.info "Skipped creating #{skipped_invalid_assessments} invalid assessments" if skipped_invalid_assessments.positive?
      Rails.logger.info "Skipped creating #{skipped_exit_assessments} exit assessments because the enrollment is open" if skipped_exit_assessments.positive?

      return unless data_collection_stages.include?(1) && generate_empty_intakes

      # For INTAKE assessments:
      # If generate_empty_intakes option is set, then generate empty intake assessments for any enrollment in the batch
      # that is missing an intake. This wouild occur if the enrollment didn't have any related records with DataCollectionStage:1.
      enrollments_missing_intakes = enrollment_batch.left_outer_joins(:intake_assessment).
        where(intake_assessment: { id: nil }).
        where.not(enrollment_id: skipped_intake_enrollment_ids) # enrollment_ids with intake assessments that were skipped because they were invalid

      empty_intakes = enrollments_missing_intakes.map(&:build_synthetic_intake_assessment)

      Rails.logger.info "Importing #{enrollments_missing_intakes.count} empty intake assessments"
      ar_import(empty_intakes)
    end

    private

    def ar_import(assessments)
      return unless assessments.any?

      options = {
        batch_size: 1_000,
        validate: false, # already validated
        recursive: true, # so FormProcessor gets saved
      }
      result = Hmis::Hud::CustomAssessment.import(assessments, options)
      return unless result.failed_instances.present?

      raise "Aborting, failed to import assessments in batch: #{result.failed_instances}"
    end

    # "values" has shape  {:id=>[6, 7], :user_id=>["548", "548"], :date_updated=>[yesterday, today]}
    # returns a modified version with duplicates removed, like: {:id=>[7], :user_id=>["548"], :date_updated=>[today]}
    def remove_duplicates(values, klass)
      # Choose which array index is going to be the "chosen" record (most recently updated)
      chosen_idx = values[:date_updated].each_with_index.max_by { |dt, _| dt.to_date }.last

      # If a specific source hash is preferred, choose that one
      if preferred_source_hash
        found_idx = values[:source_hash].find_index { |hash| hash == preferred_source_hash }
        chosen_idx = found_idx if found_idx.present?
      end

      # Remove everything else
      values_without_dups = values.transform_values { |vals| [vals[chosen_idx]] }
      # Chosen Record ID
      record_id = values_without_dups[:id].first

      # If there were more than 1 matching record, log and mark others for deletion
      if values[:id].size > 1
        Rails.logger.info "More than 1 #{klass.name} for key. IDs: #{values[:id]}. Choosing #{record_id}."
        ids_to_delete = values[:id].excluding(record_id)
        mark_for_deletion(klass, ids_to_delete)
      end
      values_without_dups
    end

    def system_user
      @system_user ||= Hmis::Hud::User.system_user(data_source_id: data_source_id)
    end

    def hud_users_by_id
      @hud_users_by_id ||= Hmis::Hud::User.where(data_source_id: data_source_id).index_by(&:user_id)
    end

    def project_scope
      @project_scope ||= begin
        scope = Hmis::Hud::Project.where(data_source_id: data_source_id)
        scope = scope.where(id: project_ids) if project_ids.any?
        scope
      end
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

    def log_assessment_summary
      assessment_scope = Hmis::Hud::CustomAssessment.joins(:project).merge(project_scope)
      open_enrollment_assessment_scope = Hmis::Hud::CustomAssessment.joins(:enrollment).merge(full_enrollment_scope.open_on_date)

      num_enrollments = full_enrollment_scope.count
      num_open_enrollments = full_enrollment_scope.open_on_date.count
      num_exited_enrollments = full_enrollment_scope.exited.count

      msgs = []
      msgs << summarize(assessment_scope.intakes.size, num_enrollments, msg: 'of enrollments have intake assessments')
      msgs << summarize(open_enrollment_assessment_scope.intakes.size, num_open_enrollments, msg: 'of open enrollments have intake assessments')
      msgs << summarize(assessment_scope.exits.size, num_exited_enrollments, msg: 'of exited enrollments have exit assessments')
      msgs << summarize(open_enrollment_assessment_scope.exits.size, num_open_enrollments, msg: 'of open enrollments have exit assessments')
      msgs << summarize(assessment_scope.annuals.size, num_enrollments, msg: 'of enrollments have annual assessments')
      msgs << summarize(assessment_scope.updates.size, num_enrollments, msg: 'of enrollments have update assessments')
      summary = msgs.join("\n")
      debug_log("Assessments Summary:\n #{summary}")
    end

    def debug_log(message)
      @notifier&.ping(message)
    end
  end
end
