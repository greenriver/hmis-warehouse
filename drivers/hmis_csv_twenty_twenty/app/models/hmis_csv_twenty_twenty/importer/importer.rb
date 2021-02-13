# frozen_string_literal: true

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Assumptions:
# The import is authoritative for the date range specified in the Export.csv file
# The import is authoritative for the projects specified in the Project.csv file
# There's no reason to have client records with no enrollments
# All tables that hang off a client also hang off enrollments

# reload!; importer = HmisCsvTwentyTwenty::Importer::Importer.new(loader_id: 2, data_source_id: 14, debug: true); importer.import!

module HmisCsvTwentyTwenty::Importer
  class Importer
    include TsqlImport
    include NotifierConfig
    include HmisTwentyTwenty

    attr_accessor :logger, :notifier_config, :import, :range, :data_source, :importer_log

    SELECT_BATCH_SIZE = 10_000
    INSERT_BATCH_SIZE = 5_000

    def initialize(
      loader_id:,
      data_source_id:,
      logger: Rails.logger,
      debug: true,
      deidentified: false
    )
      setup_notifier('HMIS CSV Importer 2020')
      @loader_log = HmisCsvTwentyTwenty::Loader::LoaderLog.find(loader_id.to_i)
      @data_source = GrdaWarehouse::DataSource.find(data_source_id.to_i)
      @logger = logger
      @debug = debug

      @deidentified = deidentified
      self.importer_log = setup_import
      importable_files.each_key do |file_name|
        setup_summary(file_name)
      end
      log('De-identifying clients') if @deidentified
      log('Limiting to pre-approved projects') if @project_whitelist
    end

    def self.module_scope
      'HmisCsvTwentyTwenty::Importer'
    end

    private def log_ids
      {
        data_source_id: @data_source.id,
        loader_log_id: @loader_log&.id,
        importer_log_id: @importer_log.id,
      }
    end

    def import!
      # log that we're waiting, but then continue on.
      already_running_for_data_source?

      GrdaWarehouse::DataSource.with_advisory_lock("hud_import_#{data_source.id}") do
        start_import
        pre_process!
        validate_data_set!
        aggregate!
        cleanup_data_set!
        # refuse to proceed with the import if there are any errors and that setting is in effect
        if should_pause?
          pause_import
        else
          ingest!
          invalidate_aggregated_enrollments!
          complete_import
        end
      end
    end

    def resume!
      return unless importer_log.resuming?

      logger.info "resume! #{hash_as_log_str log_ids}"

      # this isn't quite right, but we don't store it,
      # and we may have paused for a significant amount of time
      @started_at = Time.current
      ingest!
      invalidate_aggregated_enrollments!
      complete_import
    end

    def should_pause?
      return false unless @data_source.refuse_imports_with_errors

      db_errors = HmisCsvTwentyTwenty::Importer::ImportError.where(
        importer_log_id: importer_log.id,
      )

      validation_errors = HmisCsvValidation::Base.where(
        type: HmisCsvValidation::Error.subclasses.map(&:name),
        importer_log_id: importer_log.id,
      )
      db_errors.count.positive? || validation_errors.count.positive?
    end

    # Move all data from the data lake to either the structured, or aggregated tables
    def pre_process!
      logger.info "pre_process! #{hash_as_log_str log_ids}"
      importer_log.update(status: :pre_processing)

      importable_files.each do |file_name, klass|
        pre_process_class!(file_name, klass)
      end
    end

    private def required_file_names
      ['Export.csv', 'Project.csv']
    end

    private def use_ar_model_validations
      false
    end

    def pre_process_class!(file_name, klass)
      importer_log_id = importer_log.id
      # logger.debug { "Pre-processing #{klass.table_name} #{hash_as_log_str(importer_log_id: importer_log_id)}" }

      scope = source_data_scope_for(file_name)
      # save some allocations be doing these only once
      pre_processed_at = Time.current
      bm = Benchmark.measure do
        batch = []
        failures = []
        row_failures = []
        scope.find_each(batch_size: SELECT_BATCH_SIZE) do |source|
          row_failures = []

          # Avoiding newing up a AR model here is faster
          # run_row_validations and process_batch are both fine
          # to with with the raw source.hmis_data as a ActiveSupport::HashWithIndifferentAccess
          destination = klass.attrs_from(source, deidentified: @deidentified)
          destination['importer_log_id'] = importer_log_id
          destination['pre_processed_at'] = pre_processed_at

          # FIXME: are we sure this source_hash algo matches
          # existing import logic. If not all records will be considered modified on the next run
          destination['source_hash'] = klass.new(destination).calculate_source_hash

          row_failures = run_row_validations(klass, destination, file_name, importer_log)
          failures.concat row_failures.compact
          # Don't insert any where we have actual errors
          batch << destination unless validation_failures_contain_errors?(row_failures)
          if batch.count == INSERT_BATCH_SIZE
            process_batch!(klass, batch, file_name, type: 'pre_processed', upsert: klass.upsert?)
            batch = []
          end
          if failures.count == INSERT_BATCH_SIZE
            HmisCsvValidation::Base.import(failures, validate: use_ar_model_validations)
            failures = []
          end
        end
        process_batch!(klass, batch, file_name, type: 'pre_processed', upsert: klass.upsert?) if batch.present? # ensure we get the last batch
        HmisCsvValidation::Base.import(failures, validate: use_ar_model_validations) if failures.present?
      end

      detail_for(file_name, 'pre_process_times').tap do |stat|
        records = scope.count
        rps = (records / bm.real).round(3)
        stat['rps'] = rps
        stat['cpu_secs'] = bm.total.round(3)
        logger.debug do
          " Pre-processed #{klass.table_name} #{hash_as_log_str({ importer_log_id: importer_log_id, processed: records }.merge(stat))}"
        end
      end
    end

    private def run_row_validations(klass, row, filename, importer_log)
      failures = []
      klass.hmis_validations.each do |column, checks|
        next unless checks.present?

        checks.each do |check|
          arguments = check.dig(:arguments)
          failures << check[:class].check_validity!(row, column, arguments)
        end
      end
      failures.compact!
      importer_log.summary[filename]['total_flags'] ||= 0
      importer_log.summary[filename]['total_flags'] += failures.count
      failures
    end

    private def validation_failures_contain_errors?(failures)
      failures.any?(&:skip_row?)
    end

    def invalidate_aggregated_enrollments!
      logger.info "invalidate_aggregated_enrollments! #{hash_as_log_str log_ids}"
      importable_files.each_value do |klass|
        aggregators = aggregators_from_class(klass, @data_source)
        next unless aggregators.present?

        log("Rebuilding aggregated enrollments with #{klass.name}")
        aggregators.each do |aggregator_klass|
          aggregator_klass.new(importer_log: @importer_log, date_range: date_range).rebuild_warehouse_data
        end
      end
    end

    def aggregate!
      logger.info "aggregate! #{hash_as_log_str log_ids}"
      importer_log.update(status: :aggregating)
      importable_files.each_value do |klass|
        aggregators = aggregators_from_class(klass, @data_source)
        next unless aggregators.present?

        log("Aggregating #{klass.name}")
        aggregators.each do |aggregator_klass|
          aggregator = aggregator_klass.new(
            importer_log: @importer_log,
            date_range: date_range,
          )
          aggregator.remove_deleted_overlapping_data!
          aggregator.copy_incoming_data!
          aggregator.aggregate!
        end
      end
    end

    def validate_data_set!
      logger.info "validate_data_set! #{hash_as_log_str log_ids}"
      importable_files.each do |filename, klass|
        failures = klass.run_complex_validations!(importer_log, filename)
        HmisCsvValidation::Base.import(failures) if failures.any?
      end
    end

    def cleanup_data_set!
      logger.info "cleanup_data_set! #{hash_as_log_str log_ids}"
      importer_log.update(status: :cleaning)
      importable_files.each_value do |klass|
        cleanups = cleanups_from_class(klass, @data_source)
        next unless cleanups.present?

        log("Cleaning #{klass.name}")
        cleanups.each do |cleanup_klass|
          cleanup = cleanup_klass.new(
            importer_log: @importer_log,
            date_range: date_range,
          )
          cleanup.cleanup!
        end
      end
    end

    # Pass 0, Walk the tree starting from projects and mark all as dead (in date range where appropriate)
    # Pass 1, create any where hud-key isn't in warehouse in same data source and involved projects
    # Pass 2, pluck previous hash and DateUpdated from warehouse, joining on involved scope
    #   If hash is the same, mark as live
    #   If hash differs
    #     if the incoming DateUpdated is older, mark warehouse as live
    #     If the incoming DateUpdated is the same or newer, update warehouse from lake,
    #       mark client demographics dirty
    #       mark enrollment dirty
    #       if exit record changes also mark associated enrollment dirty
    #       mark warehouse live
    # Delete all marked as dead for data source
    # For any enrollments where history_generated_on is blank? || history_generated_on < Exit.ExitDate run equivalent of:
    # GrdaWarehouse::Tasks::ServiceHistory::Enrollment.batch_process_date_range!(range)
    # In here, add history_generated_on date to enrollment record
    def ingest!
      logger.info "ingest! #{hash_as_log_str log_ids}"
      importer_log.update(status: :importing)
      # Mark everything that exists in the warehouse, that would be covered by this import
      # as pending deletion.  We'll remove the pending where appropriate
      mark_tree_as_dead(Date.current)

      # Add Export row
      add_export_row

      # Add any records we don't have
      add_new_data

      # Process existing records,
      # determine which records have changed and are newer
      process_existing

      # Update all ExportIDs for corresponding existing warehouse records
      update_export_ids

      # Sweep all remaining items in a pending delete state
      remove_pending_deletes

      # Update the effective export end date of the export
      export_klass = importable_file_class('Export').reflect_on_association(:destination_record).klass
      export_klass.last.update(effective_export_end_date: (importable_files.except('Export.csv').map do |_, klass|
        klass.where(importer_log_id: @importer_log.id).maximum(:DateUpdated)
      end.compact + ['1900-01-01'.to_date]).max)
    end

    def aggregators_from_class(klass, data_source)
      basename = klass.name.split('::').last
      data_source.import_aggregators[basename]&.map(&:constantize)
    end

    def cleanups_from_class(klass, data_source)
      basename = klass.name.split('::').last
      data_source.import_cleanups[basename]&.map(&:constantize)
    end

    def mark_tree_as_dead(pending_date_deleted)
      importable_files.each_value do |klass|
        klass.mark_tree_as_dead(
          data_source_id: data_source.id,
          project_ids: involved_project_ids,
          date_range: date_range,
          pending_date_deleted: pending_date_deleted,
        )
      end
    end

    def add_export_row
      destination_class = export_record.class.reflect_on_association(:destination_record).klass
      destination_export = destination_class.where(
        data_source_id: data_source.id,
        ExportID: export_record.ExportID,
      ).first_or_create
      destination_export.update(export_record.as_destination_record.attributes.except('id'))
    end

    def update_export_ids
      importable_files.each do |_, klass|
        # Export has already been processed
        next if klass.hud_key == :ExportID

        klass.involved_warehouse_scope(
          data_source_id: data_source.id,
          project_ids: involved_project_ids,
          date_range: date_range,
        ).update_all(ExportID: export_record.ExportID)
      end
    end

    def add_new_data
      importable_files.each do |file_name, klass|
        destination_class = klass.reflect_on_association(:destination_record).klass
        # logger.debug "Adding #{destination_class.table_name} #{hash_as_log_str log_ids}"
        batch = []
        scope = klass.new_data(
          data_source_id: data_source.id,
          project_ids: involved_project_ids,
          date_range: date_range,
          importer_log_id: importer_log.id,
        )
        bm = Benchmark.measure do
          scope.find_each(batch_size: SELECT_BATCH_SIZE) do |row|
            batch << row.as_destination_record
            if batch.count == INSERT_BATCH_SIZE
              # NOTE: we are allowing upserts to handle the situation where data is in the warehouse with a HUD key that
              # for whatever reason doesn't fall within the involved scope
              # also NOTE: if aggregation is used, the count of added Enrollments and Exits will reflect the
              # entire history of enrollments for aggregated projects because some of the existing enrollments fall
              # outside of the range, but are necessary to calculate the correctly aggregated set
              upsert = ! destination_class.name.in?(un_updateable_warehouse_classes)
              columns = batch.first.attributes.keys - ['id']
              process_batch!(destination_class, batch, file_name, columns: columns, type: 'added', upsert: upsert)
              batch = []
            end
          end
          # NOTE: we are allowing upserts to handle the situation where data is in the warehouse with a HUD key that
          # for whatever reason doesn't fall within the involved scope
          # also NOTE: if aggregation is used, the count of added Enrollments and Exits will reflect the
          # entire history of enrollments for aggregated projects because some of the existing enrollments fall
          # outside of the range, but are necessary to calculate the correctly aggregated set
          if batch.present?
            upsert = ! destination_class.name.in?(un_updateable_warehouse_classes)
            columns = batch.first.attributes.keys - ['id']
            process_batch!(destination_class, batch, file_name, columns: columns, type: 'added', upsert: upsert) # ensure we get the last batch
          end
        end
        added = summary_for(file_name, 'added')
        detail_for(file_name, 'add_times').tap do |stat|
          rps = (added / bm.real).round(3)
          stat['rps'] = rps
          stat['cpu_secs'] = bm.total.round(3)
          logger.info do
            "  Added #{destination_class.table_name} #{hash_as_log_str({ added: added }.merge(stat).merge(log_ids))}"
          end
        end
      end
    end

    def un_updateable_warehouse_classes
      [
        'GrdaWarehouse::Hud::Export',
        'GrdaWarehouse::Hud::Client',
      ]
    end

    def process_existing
      # TODO: This could be parallelized
      importable_files.each do |file_name, klass|
        mark_unchanged(klass, file_name)
        mark_incoming_older(klass, file_name)
        apply_updates(klass, file_name)
      end
    end

    def remove_pending_deletes
      importable_files.each do |file_name, klass|
        # Never delete Exports
        next if klass.hud_key == :ExportID

        # Never delete Projects, Organizations, or Clients, but cleanup any pending deletions
        if klass.hud_key.in?([:ProjectID, :OrganizationID, :PersonalID])
          klass.existing_destination_data(data_source_id: data_source.id, project_ids: involved_project_ids, date_range: date_range).update_all(pending_date_deleted: nil)
        else
          delete_count = klass.pending_deletions(data_source_id: data_source.id, project_ids: involved_project_ids, date_range: date_range).count
          klass.existing_destination_data(data_source_id: data_source.id, project_ids: involved_project_ids, date_range: date_range).update_all(pending_date_deleted: nil, DateDeleted: Time.current, source_hash: nil)
          note_processed(file_name, delete_count, 'removed')
        end
      end
    end

    def involved_project_ids
      @involved_project_ids ||= HmisCsvTwentyTwenty::Importer::Project.
        where(importer_log_id: importer_log.id).
        pluck(:ProjectID)
    end

    # At this point,
    #   * All new data has been added
    #   * All extraneous data has been deleted
    #   * All unchanged data has been marked as live
    #   * All existing data currently marked as delete pending, should be updated from the incoming data
    # apply updates will:
    #   Mark client demographics dirty
    #   Mark enrollment dirty, for Enrollment and Exit tables
    #   Mark warehouse live
    private def apply_updates(klass, file_name)
      # Exports are always inserts, never updates
      return if klass.hud_key == :ExportID

      destination_class = klass.reflect_on_association(:destination_record).klass
      # logger.debug "Updating #{destination_class.name} #{hash_as_log_str log_ids}"

      existing = klass.existing_destination_data(
        data_source_id: data_source.id,
        project_ids: involved_project_ids,
        date_range: date_range,
      ).distinct.pluck(klass.hud_key)
      bm = Benchmark.measure do
        batch = []
        existing.each_slice(SELECT_BATCH_SIZE) do |hud_keys|
          klass.should_import.where(
            importer_log_id: @importer_log.id,
            klass.hud_key => hud_keys,
          ).find_each(batch_size: SELECT_BATCH_SIZE) do |source|
            destination = source.as_destination_record
            destination.pending_date_deleted = nil
            case klass.hud_key
            when :PersonalID
              destination.demographic_dirty = true
            when :EnrollmentID
              destination.processed_as = nil
            when :ExitID
              # These are tracked separately so we can bulk update them at the end
              track_dirty_enrollment(destination.EnrollmentID)
            end
            batch << destination
            if batch.count == INSERT_BATCH_SIZE
              # Client model doesn't have a uniqueness constraint because of the warehouse data source
              # so these must be processed more slowly
              if klass.hud_key == :PersonalID
                batch.each do |incoming|
                  destination_class.where(
                    data_source_id: incoming.data_source_id,
                    PersonalID: incoming.PersonalID,
                  ).with_deleted.update_all(incoming.slice(klass.upsert_column_names(version: '2020')))
                end
                note_processed(file_name, batch.count, 'updated')
              else
                process_batch!(destination_class, batch, file_name, type: 'updated', upsert: true)
              end
              batch = []
            end
          end
        end
        if batch.present? # ensure we get the last batch
          if klass.hud_key == :PersonalID
            batch.each do |incoming|
              destination_class.where(
                data_source_id: incoming.data_source_id,
                PersonalID: incoming.PersonalID,
              ).with_deleted.update_all(incoming.slice(klass.upsert_column_names(version: '2020')))
            end
            note_processed(file_name, batch.count, 'updated')
          else
            process_batch!(destination_class, batch, file_name, type: 'updated', upsert: true)
          end
        end

        # If we tracked any dirty enrollments, we can mark them all dirty now
        if klass.hud_key == :ExitID
          GrdaWarehouse::Hud::Enrollment.where(data_source_id: data_source.id, EnrollmentID: dirty_enrollment_ids).
            update_all(processed_as: nil)
        end
      end
      updated = summary_for(file_name, 'updated')
      detail_for(file_name, 'update_times').tap do |stat|
        rps = (updated / bm.real).round(3)
        stat['rps'] = rps
        stat['cpu_secs'] = bm.total.round(3)
        logger.info do
          "  Updated #{destination_class.table_name} #{hash_as_log_str({ updated: updated }.merge(stat).merge(log_ids))}"
        end
      end
    end

    private def mark_unchanged(klass, file_name)
      # We always bring over Exports
      return if klass.hud_key == :ExportID

      existing = klass.existing_destination_data(
        data_source_id: data_source.id,
        project_ids: involved_project_ids,
        date_range: date_range,
      ).where.not(DateUpdated: nil). # A bad import can sometimes cause this
        pluck(klass.hud_key, :source_hash)
      incoming = klass.should_import.where(importer_log_id: @importer_log.id).
        pluck(klass.hud_key, :source_hash)
      unchanged = (existing & incoming).map(&:first)
      unchanged.each_slice(INSERT_BATCH_SIZE) do |batch|
        query = klass.warehouse_class.where(
          data_source_id: data_source.id,
          klass.hud_key => batch,
        )
        query = query.with_deleted if klass.warehouse_class.paranoid?
        query.update_all(pending_date_deleted: nil)
        note_processed(file_name, batch.count, 'unchanged')
      end
    end

    private def mark_incoming_older(klass, file_name)
      # Doesn't apply to Exports
      return if klass.hud_key == :ExportID

      existing = klass.existing_destination_data(
        data_source_id: data_source.id,
        project_ids: involved_project_ids,
        date_range: date_range,
      ).pluck(klass.hud_key, :DateUpdated).to_h
      incoming = klass.should_import.where(importer_log_id: @importer_log.id).
        pluck(klass.hud_key, :DateUpdated).to_h

      # ignore any where we don't have a DateUpdated,
      # or we don't have a matching incoming record
      existing.reject! { |k, v| v.blank? || incoming[k].blank? }

      # if the incoming DateUpdated is strictly less than the existing one
      # trust the warehouse is correct
      unchanged = existing.select { |k, v| incoming[k].to_date < v.to_date }.keys
      unchanged.each_slice(INSERT_BATCH_SIZE) do |batch|
        query = klass.warehouse_class.where(
          data_source_id: data_source.id,
          klass.hud_key => batch,
        )
        query = query.with_deleted if klass.warehouse_class.paranoid?
        query.update_all(pending_date_deleted: nil)
        note_processed(file_name, batch.count, 'unchanged')
      end
    end

    private def track_dirty_enrollment(enrollment_id)
      @track_dirty_enrollment ||= Set.new
      @track_dirty_enrollment << enrollment_id
    end

    private def dirty_enrollment_ids
      @track_dirty_enrollment
    end

    private def process_batch!(klass, batch, file_name, type:, upsert:, columns: klass.upsert_column_names(version: '2020')) # rubocop:disable Metrics/ParameterLists
      klass.logger.debug { "process_batch! #{klass} #{upsert ? 'upsert' : 'import'} #{batch.size} records" }
      klass.logger.silence(Logger::WARN) do
        if upsert
          klass.import(batch, on_duplicate_key_update:
            {
              conflict_target: klass.conflict_target,
              columns: columns,
            }, validate: use_ar_model_validations)
        else
          klass.import(batch, validate: use_ar_model_validations)
        end
        note_processed(file_name, batch.count, type)
      end
      return nil
    rescue StandardError => e
      log "batch failed: #{e.message}... processing records one at a time"
      errors = []
      batch.each do |row|
        row.save!(validate: use_ar_model_validations)
        note_processed(file_name, 1, type)
      rescue StandardError => e
        errors << add_error(file: file_name, klass: klass, source_id: row.source_id, message: e.message)
      end
      @importer_log.import_errors.import(errors)
    end

    private def source_data_scope_for(file_name)
      scope = @loader_log.class.importable_files[file_name]
      scope.unscoped.where(loader_id: @loader_log.id)
    end

    private def date_range
      @date_range ||= Filters::DateRange.new(
        start: export_record.ExportStartDate.to_date,
        end: export_record.ExportEndDate.to_date,
      )
    end

    private def export_record
      @export_record ||= HmisCsvTwentyTwenty::Importer::Export.find_by(importer_log_id: importer_log.id)
    end

    def already_running_for_data_source?
      running = GrdaWarehouse::DataSource.advisory_lock_exists?("hud_import_#{data_source.id}")
      log("Import of Data Source: #{data_source.short_name} already running...waiting") if running
      running
    end

    def pause_import
      logger.info "pause_import #{hash_as_log_str(importer_log_id: importer_log_id)}"
      importer_log.update(status: :paused)
    end

    def note_processed(file, line_count, type)
      importer_log.summary[file][type] += line_count
    end

    def summary_for(file, type)
      importer_log.summary[file][type]
    end

    def detail_for(file, type)
      importer_log.summary[file][type] ||= {}
    end

    def setup_summary(file)
      importer_log.summary ||= {}
      importer_log.summary[file] ||= {
        'pre_processed' => 0,
        'added' => 0,
        'updated' => 0,
        'unchanged' => 0,
        'removed' => 0,
        'total_errors' => 0,
      }
    end

    def importable_files
      self.class.importable_files
    end

    def importable_file_class(name)
      self.class.importable_file_class(name)
    end

    def self.soft_deletable_sources
      importable_files_map.except('Export.csv').values.map { |name| "GrdaWarehouse::Hud::#{name}".constantize }
    end

    def setup_import
      return importer_log if importer_log.present?

      @importer_log = HmisCsvTwentyTwenty::Importer::ImporterLog.create!(
        data_source: data_source,
        summary: {},
      )
    end

    def start_import
      db_transaction do
        importer_log.update(status: :started)
        @loader_log.update(importer_log_id: importer_log.id)
        @started_at = Time.current
        log("Starting #{hash_as_log_str log_ids}.")
      end
    end

    def complete_import
      data_source.update(last_imported_at: Time.zone.now)
      importer_log.completed_at = Time.zone.now
      importer_log.upload_id = @upload.id if @upload.present?
      importer_log.save
      elapsed = Time.current - @started_at
      log("Completed importing in #{elapsed_time(elapsed)} #{hash_as_log_str log_ids}.\n#{summary_as_log_str importer_log.summary}")
    end

    private def db_transaction(&block)
      GrdaWarehouse::Hud::Base.transaction(&block)
    end

    def log(message)
      @notifier&.ping message
      logger.info "#{self.class} #{message}" if @debug
    end

    def add_error(file:, klass:, source_id:, message:)
      importer_log.summary[file]['total_errors'] += 1
      log(message)
      importer_log.import_errors.build(
        source_type: klass,
        source_id: source_id,
        message: "Error importing #{klass}",
        details: message,
      )
    end
  end
end
