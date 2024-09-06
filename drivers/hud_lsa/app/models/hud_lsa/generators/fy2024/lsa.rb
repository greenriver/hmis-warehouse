###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

if ENV['RDS_AWS_ACCESS_KEY_ID'].present? && !ENV['NO_LSA_RDS'].present?
  load 'lib/rds_sql_server/rds.rb'
  load 'lib/rds_sql_server/sql_server_base.rb'
end

# Testing notes:
# Re-use an existing report
# r = HudLsa::Generators::Fy2024::Lsa.last
# r.test = true; r.destroy_rds = false
# r.run!
module HudLsa::Generators::Fy2024
  class Lsa < ::HudReports::ReportInstance
    include TsqlImport
    include NotifierConfig
    include ActionView::Helpers::DateHelper
    include ArelHelper
    include TableConcern
    include RdsConcern
    include MissingDataConcern
    include ViewRelatedConcern
    include StatusProgressionConcern
    attr_accessor :report, :destroy_rds, :hmis_export_id, :test, :test_type
    has_one_attached :result_file
    has_one_attached :intermediate_file
    has_one :summary_result, class_name: 'HudLsa::Fy2024::SummaryResult', foreign_key: :hud_report_instance_id
    belongs_to :export, class_name: 'GrdaWarehouse::HmisExport', optional: true

    def self.find_report(user)
      where(user_id: user.id).order(created_at: :desc).first
    end

    def filter
      @filter ||= HudLsa::Filters::LsaFilter.new(user_id: user_id).update(options)
    end

    def lookback_stop_date
      filter.start - 7.years
    end

    def run!
      setup_notifier('LSA')
      @failed = preflight_passes?
      return unless @failed

      # Disable logging so we don't fill the disk
      # ActiveRecord::Base.logger.silence do
      calculate
      Rails.logger.info 'Done Calculating LSA'
      # end # End silence ActiveRecord Log
    end

    def calculate
      filter.coc_code = 'XX-501' if test?

      log_and_ping('Starting')
      begin
        # kick-off the RDS creation it often takes quite a few minutes, as does the export
        # asking AWS to create the RDS is quick
        create_temporary_rds
        create_hmis_csv_export
        update_report_progress(percent: 15)
        log_and_ping('HMIS Export complete')
        setup_temporary_rds
        update_report_progress(percent: 20)
        log_and_ping('RDS DB Setup')
        setup_hmis_table_structure
        update_report_progress(percent: 22)
        log_and_ping('HMIS Table Structure')
        setup_lsa_table_structure
        update_report_progress(percent: 25)
        log_and_ping('LSA Table Structure')
        update_report_progress(percent: 27)
        setup_lsa_table_indexes
        log_and_ping('LSA Indexes Setup')
        update_report_progress(percent: 29)
        setup_lsa_report
        log_and_ping('LSA Report Setup')

        populate_hmis_tables
        update_report_progress(percent: 30)
        log_and_ping('HMIS tables populated')

        run_lsa_queries
        update_report_progress(percent: 90)
        log_and_ping('LSA Queries complete')
        # Fetch data
        # HUD has chosen not to give some tables identity columns, rails needs these
        # to be able to fetch in batches, so we'll add them here
        add_missing_identity_columns
        fetch_results
        fetch_summary_results
        zip_report_folder
        attach_file(:result_file)
        remove_report_files
        # Fetch supporting data
        fetch_intermediate_results
        zip_report_folder
        attach_file(:intermediate_file)
        remove_report_files

        # Remove identity columns so it works again even against the same db
        remove_missing_identity_columns
        update_report_progress(percent: 100)
        log_and_ping('LSA Complete')
      ensure
        remove_temporary_rds
        FileUtils.rm_rf(unzip_path)
      end
      finish_report
    end

    # Confirm the chosen projects are not missing critical data.
    # Any structural failures that will cause the run to fail should be caught here
    private def preflight_passes?
      issues = missing_data(user).except(:show_missing_data)
      issue_project_ids = issues.values.flatten.map { |r| r[:id] }.uniq & filter.effective_project_ids_during_range(export_date_range)
      return true if issue_project_ids.empty?

      # Prevent report.complete_report from hiding the error
      @failed = true
      project_names = issues.values.flatten.select { |r| r[:id].in?(issue_project_ids) }.map do |r|
        "#{r[:project]} (id: #{r[:id]})"
      end.uniq
      failure = "The following projects are missing data that will cause the LSA to fail: #{project_names.join(', ')}"
      log_and_ping("LSA failed: #{failure}")
      fail_report(failure)
      false
    end

    def run_lsa_queries
      ::Rds.identifier = sql_server_identifier unless Rds.static_rds?
      ::Rds.database = sql_server_database
      ::Rds.timeout = 60_000_000
      load 'lib/rds_sql_server/lsa/fy2024/lsa_queries.rb'
      rep = LsaSqlServer::LSAQueries.new
      rep.test_run = test?
      rep.project_ids = filter.effective_project_ids_during_range(export_date_range)

      # some setup
      if test?
        rep.setup_test_projects
      else
        rep.insert_projects
      end

      # loop through the LSA queries
      # This starts at 30%, ends at 90%
      step_percent = 60.0 / rep.steps.count
      rep.steps.each_with_index do |step, i|
        percent = 30 + i * step_percent
        update_report_progress(percent: percent.round(2))
        start_time = Time.current
        rep.run_query(step)
        end_time = Time.current
        seconds = ((end_time - start_time) / 1.minute).round * 60
        log_and_ping("LSA Query #{step} complete in #{distance_of_time_in_words(seconds)}")
      end
    end

    def fetch_summary_results
      load 'lib/rds_sql_server/lsa/fy2024/lsa_report_summary.rb'
      summary = LsaSqlServer::LSAReportSummary.new
      summary_result&.destroy!
      self.summary_result = nil
      save!
      create_summary_result(summary: summary.fetch_summary)
    end

    private def export_date_range
      # Special case for HIC.  This will generally be a 1 day run,
      # but check for a slightly larger range since the LSA will almost always be a year.
      # When running the HIC, we don't want the full look-back because it will include
      # projects that were not operating during the report range, and thus shouldn't be included in the HIC
      return filter.range if filter.range.count < 5

      lookback_stop_date .. filter.end
    end

    def create_hmis_csv_export
      return if test?

      if @hmis_export_id && GrdaWarehouse::HmisExport.where(id: @hmis_export_id).exists?
        @hmis_export = GrdaWarehouse::HmisExport.find(@hmis_export_id)
        update(export_id: @hmis_export.id)
        return
      end

      # All LSA reports should have the same HMIS export scope, so reuse the file if available from today
      # This is really only useful if you are changing the code, so only reuse the export in development
      if Rails.env.development?
        existing_export = GrdaWarehouse::HmisExport.order(created_at: :desc).limit(1).
          where(
            created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day,
            start_date: export_date_range.first,
            version: 2024,
            period_type: 3,
            directive: 2,
            hash_status: 1,
            include_deleted: false,
          ).
          # where project_ids contains the effective project ids, and effective contains the project ids
          # (equivalency without sort)
          where('project_ids @> ?', filter.effective_project_ids_during_range(export_date_range).to_json).
          where('project_ids <@ ?', filter.effective_project_ids_during_range(export_date_range).to_json).
          where.not(file: nil)&.first
        if existing_export.present?
          @hmis_export = existing_export
          update(export_id: @hmis_export.id)
          return
        end
      end

      @hmis_export = HmisCsvTwentyTwentyFour::Exporter::Base.new(
        version: '2024',
        start_date: export_date_range.first,
        end_date: export_date_range.last,
        projects: filter.effective_project_ids_during_range(export_date_range),
        coc_codes: filter.coc_code,
        period_type: 3,
        directive: 2,
        hash_status: 1,
        include_deleted: false,
        user_id: user_id,
        options: filter.to_h,
      ).export!
      update(export_id: @hmis_export.id)
    end

    def unzip_path
      path = File.join('tmp', 'lsa', id.to_s)
      FileUtils.mkdir_p(path) unless Dir.exist?(path)
      path
    end

    def zip_path
      File.join(unzip_path, "#{id}.zip")
    end

    def zip_report_folder
      files = Dir.glob(File.join(unzip_path, '*')).map { |f| File.basename(f) }
      Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        files.each do |file_name|
          zipfile.add(
            file_name,
            File.join(unzip_path, file_name),
          )
        end
      end
    end

    def attach_file(file_type)
      path = Pathname.new(zip_path)
      send(file_type).attach(
        io: path.open,
        filename: path.basename,
        content_type: 'application/zip',
        identify: false,
      )
    end

    def remove_report_files
      FileUtils.rm_rf(unzip_path)
    end

    def populate_hmis_tables
      load 'lib/rds_sql_server/lsa/fy2024/hmis_sql_server.rb' # provides thin wrappers to all HMIS tables
      extract_path = if test?
        source = Rails.root.join('drivers/hud_lsa/spec/fixtures/files/lsa/fy2024/sample_hmis_export/')
        existing = Dir.glob(File.join(unzip_path, '*.csv'))
        FileUtils.rm(existing) if existing
        Dir.glob(File.join(source, '*.csv')).each do |f|
          FileUtils.cp_r(f, unzip_path)
        end
        unzip_path
      else
        @hmis_export.unzip_to(unzip_path)
      end
      read_rows = 50_000
      HmisSqlServer.models_by_hud_filename.each do |file_name, klass|
        # Delete any existing data
        klass.delete_all
        klass.reset_column_information
        # Read the file in batches to avoid over RAM usage
        File.open(File.join(extract_path, file_name)) do |file|
          headers = file.first
          file.lazy.each_slice(read_rows) do |lines|
            content = ::CSV.parse(lines.join, headers: headers)
            import_headers = content.first.headers
            next unless content.any?

            # this fixes dates that default to 1900-01-01 if you send an empty string
            content = content.map do |row|
              klass.new.clean_row_for_import(row: row.fields, headers: import_headers)
            end.compact
            # Using TsqlImport because active_record import doesn't play nice
            insert_batch(klass, standardize_headers(import_headers), content, batch_size: 1_000)
          end
        end
      end
      FileUtils.rm_rf(extract_path)
      GrdaWarehouseBase.connection.reconnect!
      ApplicationRecord.connection.reconnect!
      ReportingBase.connection.reconnect!
    end

    # This reverses some export changes we made to maintain case sensitive matching with the 2024 spec
    private def standardize_headers(headers)
      # ZIP -> Zip
      zip_index = headers.index('ZIP')
      headers[zip_index] = 'Zip' if zip_index.present?

      # WorkplaceViolenceThreats -> WorkPlaceViolenceThreats
      workplace_index = headers.index('WorkplaceViolenceThreats')
      headers[workplace_index] = 'WorkPlaceViolenceThreats' if workplace_index.present?

      headers
    end

    def fetch_results
      load 'lib/rds_sql_server/lsa/fy2024/lsa_sql_server.rb'
      # Make note of completion time, LSA requirements are very specific that this should be the time the report was completed, not when it was initiated.
      # There will only ever be one of these.
      LsaSqlServer.models_by_filename.each do |filename, klass|
        path = File.join(unzip_path, filename)
        # Sample files are not quoted when the columns are integers or dates regardless of if there is data
        force_quotes = ! klass.name.include?('LSA')
        remove_primary_key = false
        # Force a primary key for fetching in batches
        if klass.primary_key.blank?
          klass.primary_key = 'id'
          remove_primary_key = true
        end
        ::CSV.open(path, 'wb', force_quotes: force_quotes) do |csv|
          headers = klass.csv_columns.map { |m| if m == :Zip then :ZIP else m end }.map(&:to_s)
          add_rows_to_export(csv, headers: headers, klass: klass)
        end
        klass.primary_key = nil if remove_primary_key
      end
      # puts LsaSqlServer.models_by_filename.values.map(&:count).inspect
    end

    def fetch_intermediate_results
      load 'lib/rds_sql_server/lsa/fy2024/lsa_sql_server.rb'
      # Make note of completion time, LSA requirements are very specific that this should be the time the report was completed, not when it was initiated.
      # There will only ever be one of these.
      LsaSqlServer.intermediate_models_by_filename.each do |filename, klass|
        path = File.join(unzip_path, filename)
        remove_primary_key = false
        if klass.primary_key.blank?
          klass.primary_key = 'id'
          remove_primary_key = true
        end
        ::CSV.open(path, 'wb') do |csv|
          # Force a primary key for fetching in batches
          add_rows_to_export(csv, headers: klass.column_names, klass: klass)
        end
        klass.primary_key = nil if remove_primary_key
      end
      # puts LsaSqlServer.models_by_filename.values.map(&:count).inspect
    end

    private def add_rows_to_export(csv, headers:, klass:)
      csv << headers
      klass.find_each(batch_size: 10_000) do |item|
        row = []
        item.attributes.slice(*headers).each_value do |m|
          if m.is_a?(Date)
            row << m.strftime('%F')
          elsif m.is_a?(Time)
            row << m.utc.strftime('%F %T')
          else
            row << m
          end
        end
        csv << row
      end
      csv
    end

    def setup_lsa_report
      load 'lib/rds_sql_server/lsa/fy2024/lsa_sql_server.rb'
      if test?
        ::Rds.identifier = sql_server_identifier unless Rds.static_rds?
        ::Rds.database = sql_server_database
        ::Rds.timeout = 60_000_000
        load 'lib/rds_sql_server/lsa/fy2024/lsa_queries.rb'
        LsaSqlServer::LSAQueries.new.setup_test_report(type: test_type || :lsa)
      else
        LsaSqlServer::LSAReport.delete_all
        LsaSqlServer::LSAReport.create!(
          ReportID: Time.now.to_i,
          ReportDate: Date.current,
          ReportStart: filter.start,
          ReportEnd: filter.end,
          LookbackDate: lookback_stop_date,
          ReportCoC: filter.coc_code,
          SoftwareVendor: 'Green River Data Analysis',
          SoftwareName: 'OpenPath HMIS Data Warehouse',
          VendorContact: 'Elliot Anders',
          VendorEmail: 'elliot@greenriver.org',
          LSAScope: lsa_scope,
        )
      end
    end

    private def lsa_scope
      return filter.lsa_scope.to_i if filter.lsa_scope.present?

      if filter.project_ids.any?
        2
      else
        1
      end
    end

    def update_report_progress percent:
      self.update(percent_complete: percent) # rubocop:disable Style/RedundantSelf:
    end

    def test?
      @test = false if @test.nil?
      @test
    end
  end
end
