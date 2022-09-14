###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
if ENV['RDS_AWS_ACCESS_KEY_ID'].present? && !ENV['NO_LSA_RDS'].present?
  load 'lib/rds_sql_server/rds.rb'
  load 'lib/rds_sql_server/sql_server_base.rb'
end

module HudLsa::Generators::Fy2022
  class Lsa < ::HudReports::GeneratorBase
    include TsqlImport
    include NotifierConfig
    include ActionView::Helpers::DateHelper
    include ArelHelper
    include TableConcern
    include RdsConcern
    attr_accessor :report,  :send_notifications, :notifier_config

    def initialize(options: {})
      @user = User.find(options[:user_id].to_i)
      selected_options = { options: options }

      destroy_rds = options.delete(:destroy_rds)
      selected_options.merge!(destroy_rds: destroy_rds) unless destroy_rds.nil?

      hmis_export_id = options.delete(:hmis_export_id)
      selected_options.merge!(hmis_export_id: hmis_export_id) if hmis_export_id

      @destroy_rds = destroy_rds
      @hmis_export_id = hmis_export_id
      @user = User.find(options[:user_id].to_i) if options[:user_id].present?
      @test = options[:test].present?
    end

    def self.generic_title
      'Longitudinal System Analysis'
    end

    def self.short_name
      'LSA'
    end

    def self.fiscal_year
      'FY 2022'
    end

    def self.questions
      []
    end

    def run!
      setup_notifier('LSA')
      # Disable logging so we don't fill the disk
      # ActiveRecord::Base.logger.silence do
      calculate
      Rails.logger.info 'Done Calculating LSA'
      # end # End silence ActiveRecord Log
    end

    def calculate
      if start_report(HudLsa::Fy2022::Report.first)
        setup_filters
        @report_start ||= @report.options['report_start'].to_date
        @report_end ||= @report.options['report_end'].to_date
        log_and_ping("Starting report #{@report.report.name}")
        begin
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
          attach_report_zip
          remove_report_files
          # Fetch supporting data
          fetch_intermediate_results
          zip_report_folder
          attach_intermediate_report_zip
          remove_report_files

          # Remove identity columns so it works again even against the same db
          remove_missing_identity_columns
          update_report_progress(percent: 100)
          log_and_ping('LSA Complete')
        ensure
          remove_temporary_rds
        end
        finish_report
      else
        log_and_ping('No LSA Report Queued')
      end
    end

    def run_lsa_queries
      ::Rds.identifier = sql_server_identifier unless Rds.static_rds?
      ::Rds.database = sql_server_database
      ::Rds.timeout = 60_000_000
      load 'lib/rds_sql_server/lsa/fy2022/lsa_queries.rb'
      rep = LsaSqlServer::LSAQueries.new
      rep.test_run = test?
      rep.project_ids = @project_ids unless @lsa_scope == 1 # Non-System wide

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
      load 'lib/rds_sql_server/lsa/fy2022/lsa_report_summary.rb'
      summary = LsaSqlServer::LSAReportSummary.new
      @report.results = { summary: summary.fetch_summary }
      @report.save
    end

    def create_hmis_csv_export
      return if test?

      if @hmis_export_id && GrdaWarehouse::HmisExport.where(id: @hmis_export_id).exists?
        @report.export_id = @hmis_export_id
        return GrdaWarehouse::HmisExport.find(@hmis_export_id)
      end

      # All LSA reports should have the same HMIS export scope, so reuse the file if available from today
      # This is really only useful if you are changing the code, so only reuse the export in development
      if Rails.env.development?
        existing_export = GrdaWarehouse::HmisExport.order(created_at: :desc).limit(1).
          where(
            created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day,
            start_date: '2012-10-01',
            version: 2022,
            period_type: 3,
            directive: 2,
            hash_status: 1,
            include_deleted: false,
          ).
          where('project_ids @> ?', @project_ids.to_json).
          where.not(file: nil)&.first
        if existing_export.present?
          @hmis_export = existing_export
          return
        end
      end

      @hmis_export = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
        version: '2022',
        start_date: '2012-10-01', # using 10/1/2012 so we can determine continuous homelessness
        end_date: @report_end,
        projects: @project_ids,
        coc_codes: @coc_code,
        period_type: 3,
        directive: 2,
        hash_status: 1,
        include_deleted: false,
        user_id: @report.user_id,
      ).export!
      @report.export_id = @hmis_export.id
    end

    def unzip_path
      path = File.join('tmp', 'lsa', @report.id.to_s)
      FileUtils.mkdir_p(path) unless Dir.exist?(path)
      path
    end

    def zip_path
      File.join(unzip_path, "#{@report.id}.zip")
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

    def attach_report_zip
      report_file = GrdaWarehouse::ReportResultFile.new(user_id: @report.user_id)
      file = Pathname.new(zip_path).open
      report_file.content = file.read
      report_file.content_type = 'application/zip'
      report_file.save!
      @report.file_id = report_file.id
      @report.save!
    end

    def attach_intermediate_report_zip
      report_file = GrdaWarehouse::ReportResultFile.new(user_id: @report.user_id)
      file = Pathname.new(zip_path).open
      report_file.content = file.read
      report_file.content_type = 'application/zip'
      report_file.save!
      @report.support_file_id = report_file.id
      @report.save!
    end

    def remove_report_files
      FileUtils.rm_rf(unzip_path)
    end

    def populate_hmis_tables
      load 'lib/rds_sql_server/lsa/fy2022/hmis_sql_server.rb' # provides thin wrappers to all HMIS tables
      extract_path = if test?
        source = Rails.root.join('spec/fixtures/files/lsa/fy2022/sample_hmis_export/')
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
            content = CSV.parse(lines.join, headers: headers)
            import_headers = content.first.headers
            next unless content.any?

            # this fixes dates that default to 1900-01-01 if you send an empty string
            content = content.map do |row|
              klass.new.clean_row_for_import(row: row.fields, headers: import_headers)
            end.compact
            # Using TsqlImport because active_record import doesn't play nice
            insert_batch(klass, import_headers, content, batch_size: 1_000)
          end
        end
      end
      FileUtils.rm_rf(extract_path)
      GrdaWarehouseBase.connection.reconnect!
      ApplicationRecord.connection.reconnect!
      ReportingBase.connection.reconnect!
    end

    def fetch_results
      load 'lib/rds_sql_server/lsa/fy2022/lsa_sql_server.rb'
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
        CSV.open(path, 'wb', force_quotes: force_quotes) do |csv|
          headers = klass.csv_columns.map { |m| if m == :Zip then :ZIP else m end }.map(&:to_s)
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
        end
        klass.primary_key = nil if remove_primary_key
      end
      # puts LsaSqlServer.models_by_filename.values.map(&:count).inspect
    end

    def fetch_intermediate_results
      load 'lib/rds_sql_server/lsa/fy2022/lsa_sql_server.rb'
      # Make note of completion time, LSA requirements are very specific that this should be the time the report was completed, not when it was initiated.
      # There will only ever be one of these.
      LsaSqlServer.intermediate_models_by_filename.each do |filename, klass|
        path = File.join(unzip_path, filename)
        remove_primary_key = false
        if klass.primary_key.blank?
          klass.primary_key = 'id'
          remove_primary_key = true
        end
        CSV.open(path, 'wb') do |csv|
          # Force a primary key for fetching in batches
          headers = klass.column_names
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
        end
        klass.primary_key = nil if remove_primary_key
      end
      # puts LsaSqlServer.models_by_filename.values.map(&:count).inspect
    end

    def setup_lsa_report
      load 'lib/rds_sql_server/lsa/fy2022/lsa_sql_server.rb'
      if test?
        ::Rds.identifier = sql_server_identifier unless Rds.static_rds?
        ::Rds.database = sql_server_database
        ::Rds.timeout = 60_000_000
        load 'lib/rds_sql_server/lsa/fy2022/lsa_queries.rb'
        LsaSqlServer::LSAQueries.new.setup_test_report
      else
        LsaSqlServer::LSAReport.delete_all
        LsaSqlServer::LSAReport.create!(
          ReportID: Time.now.to_i,
          ReportDate: Date.current,
          ReportStart: @report_start,
          ReportEnd: @report_end,
          ReportCoC: @coc_code,
          SoftwareVendor: 'Green River Data Analysis',
          SoftwareName: 'OpenPath HMIS Data Warehouse',
          VendorContact: 'Elliot Anders',
          VendorEmail: 'elliot@greenriver.org',
          LSAScope: lsa_scope,
        )
      end
    end

    def log_and_ping msg
      msg = "#{msg} (ReportResult: #{@report&.id}, percent_complete: #{@report&.percent_complete})"
      Rails.logger.info msg
      @notifier.ping(msg) if @send_notifications
    end

    def setup_filters
      # convert various inputs to project ids for the HUD HMIS export
      project_group_ids = @report.options['project_group_ids'].delete_if(&:blank?).map(&:to_i)
      if project_group_ids.any?
        project_group_project_ids = GrdaWarehouse::ProjectGroup.where(id: project_group_ids).map(&:project_ids).flatten.compact
        @report.options['project_id'] |= project_group_project_ids
      end
      data_source_ids = @report.options['data_source_ids']&.select(&:present?)&.map(&:to_i) || []
      @report.options['project_id'] |= GrdaWarehouse::Hud::Project.where(data_source_id: data_source_ids).pluck(:id) if data_source_ids.present?
      if test?
        @coc_code = 'XX-500'
      else
        @coc_code = @report.options['coc_code']
      end
      if @report.options['project_id'].delete_if(&:blank?).any?
        @project_ids = @report.options['project_id'].delete_if(&:blank?).map(&:to_i)
        # Limit to only those projects the user who queued the report can see
        # and to only those that the LSA can handle
        @project_ids &= GrdaWarehouse::Hud::Project.viewable_by(@report.user).
          in_coc(coc_code: @coc_code).
          with_hud_project_type([1, 2, 3, 8, 9, 10, 13]).
          coc_funded.
          pluck(:id)
      else
        # Confirmed with HUD only project types 1, 2, 3, 8, 9, 10, 13 need to be included in hmis_ tables.
        @project_ids = system_wide_project_ids
      end
    end

    def system_wide_project_ids
      @system_wide_project_ids ||= GrdaWarehouse::Hud::Project.viewable_by(@user).
        in_coc(coc_code: @coc_code).
        with_hud_project_type([1, 2, 3, 8, 9, 10, 13]).
        coc_funded.
        pluck(:id).sort
    end

    private def lsa_scope
      return @report.options['lsa_scope'].to_i if @report.options['lsa_scope'].present?

      if @report.options['project_id'].delete_if(&:blank?).any?
        2
      else
        1
      end
    end

    def set_report_start_and_end
      @report_start ||= @report.options['report_start'].to_date
      @report_end ||= @report.options['report_end'].to_date # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    def update_report_progress percent:
      @report.update(
        percent_complete: percent,
      )
    end

    def start_report(report)
      # Find the first queued report
      @report = ReportResult.where(
        report: report,
        percent_complete: 0,
      ).first

      # Debugging
      # @report = ReportResult.find(902)

      return unless @report.present?

      Rails.logger.info "Starting report #{@report.report.name}"
      @report.update(percent_complete: 0.01)
    end

    def finish_report
      @report.update(
        percent_complete: 100,
        completed_at: Time.now,
      )
    end

    def household_types
      @household_types ||= {
        nil: 'All',
        1 => 'AO',
        2 => 'AC',
        3 => 'CO',
      }
    end

    def test?
      @test
    end

    def destroy_rds?
      @destroy_rds
    end
  end
end
