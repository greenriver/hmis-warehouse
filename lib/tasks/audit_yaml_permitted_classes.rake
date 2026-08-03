###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

namespace :audit do
  desc 'Report any Ruby classes embedded in existing YAML-serialized data that would be rejected by ' \
       'config.active_record.yaml_column_permitted_classes. Run against a production/staging copy before ' \
       'and after changing that setting. Read-only: never modifies data.'
  task yaml_permitted_classes: :environment do
    # Reads the actual live setting rather than a separately hand-maintained copy, so this
    # audit can't silently drift from what's really enforced. To preview a candidate change
    # before committing it, temporarily edit config.active_record.yaml_column_permitted_classes
    # in config/application.rb and re-run this task against a production/staging copy.
    candidate_permitted_classes = ActiveRecord.yaml_column_permitted_classes

    # Some of these tables (PaperTrail::Version especially) can hold millions of rows in
    # production — page through by primary key instead of loading the whole table at once.
    batch_size = 2_000

    # Yields each row's non-id column value(s) in id order, batch_size rows at a time, via
    # keyset (WHERE id > last_id) pagination rather than OFFSET (which gets slower as the
    # offset grows on a large table).
    each_batch = lambda do |klass, columns, &block|
      last_id = 0
      select_list = (['id'] + Array(columns)).join(', ')
      loop do
        rows = klass.connection.select_rows(
          "SELECT #{select_list} FROM #{klass.table_name} WHERE id > #{last_id} ORDER BY id LIMIT #{batch_size}",
        )
        break if rows.empty?

        rows.each { |row| block.call(row[1..]) }
        last_id = rows.last.first.to_i
      end
    end

    # [model, column, extra_permitted_classes] for every `serialize`-declared column using the
    # (implicit) YAML coder. GrdaWarehouse::FakeData#map/#client_ids use `coder: JSON` and are
    # not affected — excluded. Cohort#column_state carries its own additional allow-list
    # (matching the per-column `serialize ..., yaml: { permitted_classes: ... }` override in
    # app/models/grda_warehouse/cohort.rb) so this audit reflects the real production config
    # rather than perpetually flagging every CohortColumns::* class as unresolved.
    serialized_yaml_columns = [
      [GrdaWarehouse::ImportLog, :files, []],
      [GrdaWarehouse::ImportLog, :import_errors, []],
      [GrdaWarehouse::ImportLog, :summary, []],
      [GrdaWarehouse::ClientMatch, :score_details, []],
      [GrdaWarehouse::HmisForm, :api_response, []],
      [GrdaWarehouse::HmisForm, :answers, []],
      [GrdaWarehouse::HmisClient, :case_manager_attributes, []],
      [GrdaWarehouse::HmisClient, :assigned_staff_attributes, []],
      [GrdaWarehouse::HmisClient, :counselor_attributes, []],
      [GrdaWarehouse::HmisClient, :outreach_counselor_attributes, []],
      [GrdaWarehouse::Config, :client_details, []],
      [GrdaWarehouse::Cohort, :column_state, GrdaWarehouse::Cohorts::CohortColumn.known_cohort_columns.map(&:constantize)],
      [Health::Careplan, :service_archive, []],
      [Health::Careplan, :equipment_archive, []],
      [Health::Careplan, :team_members_archive, []],
      [Health::Careplan, :goals_archive, []],
      [Health::Careplan, :backup_plan_archive, []],
      [HmisSupplemental::DataSet, :fields, []],
    ].freeze

    check_raw_yaml = lambda do |raw, permitted_classes, offenders|
      next if raw.blank?

      begin
        YAML.safe_load(raw, permitted_classes: permitted_classes, aliases: true)
      rescue Psych::DisallowedClass => e
        class_name = e.message[/unspecified class: (.+)\z/, 1] || e.message
        offenders[class_name] += 1
      rescue Psych::Exception => e
        offenders["<parse error: #{e.class}>"] += 1
      end
    end

    report = lambda do |label, checked, offenders|
      status = offenders.empty? ? 'OK' : 'NEEDS ATTENTION'
      puts "#{label}: checked #{checked} row(s) - #{status}"
      offenders.each { |klass, count| puts "    #{klass} (#{count} row(s))" }
    end

    puts '=' * 80
    puts 'YAML permitted-classes audit'
    puts "Candidate permitted classes: #{candidate_permitted_classes.map(&:name).join(', ')}"
    puts '=' * 80

    puts
    puts '--- serialize-declared columns (raw SQL, bypassing the current unsafe-load coder) ---'
    serialized_yaml_columns.each do |model, column, extra_permitted_classes|
      next unless model.table_exists?

      # The `serialize` declaration can drift from the live schema (a column renamed or
      # dropped since this list was written) without raising until it's actually queried
      # — skip and flag rather than let one stale entry abort the whole audit.
      unless model.column_names.include?(column.to_s)
        puts "#{model.name}##{column}: SKIPPED - column not found on #{model.table_name} (schema drift? check the model)"
        next
      end

      offenders = Hash.new(0)
      checked = 0
      permitted = candidate_permitted_classes + extra_permitted_classes
      each_batch.call(model, [column]) do |(raw)|
        checked += 1
        check_raw_yaml.call(raw, permitted, offenders)
      end
      report.call("#{model.name}##{column}", checked, offenders)
    end

    puts
    puts '--- PaperTrail versions (object / object_changes) ---'
    [PaperTrail::Version, Health::HealthVersion].each do |version_class|
      next unless version_class.table_exists?

      offenders = Hash.new(0)
      checked = 0
      columns = version_class.column_names & ['object', 'object_changes']
      each_batch.call(version_class, columns) do |row|
        checked += 1
        row.each { |raw| check_raw_yaml.call(raw, candidate_permitted_classes, offenders) }
      end
      report.call(version_class.name, checked, offenders)
    end

    puts
    puts '--- Delayed::Job#handler (HMIS export jobs) ---'
    # Matches HmisExportsController#set_jobs's JOB_HANDLER_PERMITTED_CLASSES — this is the
    # actual enforced list for that controller's narrow, closed set of job classes. It does NOT
    # reflect what the general admin/delayed_jobs job-queue view can handle (that view reads via
    # Delayed::Job#payload_object, which is unrestricted and out of scope).
    job_permitted_classes = [ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper, Symbol, Date, Time]
    offenders = Hash.new(0)
    checked = 0
    # Delayed::Job is a normal AR scope here (unlike the raw-SQL reads above, which
    # deliberately bypass AR so as not to invoke the very unsafe-load coder being audited),
    # so Rails' own batch-finder covers pagination.
    Delayed::Job.jobs_for_class(::Filters::HmisExport.job_classes).find_each(batch_size: batch_size) do |job|
      checked += 1
      check_raw_yaml.call(job.handler, job_permitted_classes, offenders)
    end
    report.call('Delayed::Job#handler', checked, offenders)

    puts
    puts '=' * 80
    puts 'Done. Add any listed classes to the relevant permitted_classes list before relying on this change.'
    puts '=' * 80
  end
end
