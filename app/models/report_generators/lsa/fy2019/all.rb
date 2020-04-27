###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# Some testing code:
# Most recent LSA needs these options: Report Start: Oct 1, 2016; Report End: Sep 30, 2017; CoC-Code: XX-500
#
# reload!; report_id = Reports::Lsa::Fy2019::All.last.id; ReportResult.where(report_id: report_id).last.update(percent_complete: 0); rg = ReportGenerators::Lsa::Fy2019::All.new(destroy_rds: false); rg.run!
#
# Conversion notes:
# 1. Break table creation sections into their own methods
# 2. Move lSA reference tables from the end to before the lsa queries method
# 3. Take note of any queries in lsa_queries with a comment of CHANGED, these will need to be
#    looked at, and potentially updated, prior to replacing
# 4. Break up the queries (submitting after each) to prevent timeouts (maybe increase timeout?)
#    Replace "/*"" with
#    "SQL
#     SqlServerBase.connection.execute (<<~SQL);
#     /*"
# 5. Remove insert statement for lsa_Report that starts with "INSERT [dbo].[lsa_Report]"


# This check is a proxy for all the vars you really need in the rds.rb file
# This if-statement prevents the lack of the vars from killing the app.

if ENV['RDS_AWS_ACCESS_KEY_ID'].present? && !ENV['NO_LSA_RDS'].present?
  load 'lib/rds_sql_server/rds.rb'
  load 'lib/rds_sql_server/sql_server_base.rb'
end

module ReportGenerators::Lsa::Fy2019
  class All < Base
    include TsqlImport
    include NotifierConfig
    include ActionView::Helpers::DateHelper
    attr_accessor :send_notifications, :notifier_config

    def initialize options
      @user = User.find(options[:user_id].to_i)
    end

    def run!
      setup_notifier('LSA')
      # Disable logging so we don't fill the disk
      # ActiveRecord::Base.logger.silence do
        calculate()
        Rails.logger.info "Done"
      # end # End silence ActiveRecord Log
    end

    # private

    def calculate
      if start_report(Reports::Lsa::Fy2019::All.first)
        setup_filters()
        @report_start ||= @report.options['report_start'].to_date
        @report_end ||= @report.options['report_end'].to_date
        log_and_ping("Starting report #{@report.report.name}")
        begin
          @hmis_export = create_hmis_csv_export()
          update_report_progress percent: 15
          log_and_ping('HMIS Export complete')
          setup_temporary_rds()
          update_report_progress percent: 20
          log_and_ping('RDS DB Setup')
          setup_hmis_table_structure()
          log_and_ping('HMIS Table Structure')
          setup_lsa_table_structure()
          log_and_ping('LSA Table Structure')
          # setup_lsa_table_indexes()
          # log_and_ping('LSA Indexes')

          update_report_progress percent: 22
          setup_lsa_report()
          log_and_ping('LSA Report Setup')

          populate_hmis_tables()
          update_report_progress percent: 30
          log_and_ping('HMIS tables populated')

          run_lsa_queries()
          update_report_progress percent: 90
          log_and_ping('LSA Queries complete')
          fetch_results()
          # fetch_summary_results()
          zip_report_folder()
          attach_report_zip()
          remove_report_files()
          update_report_progress percent: 100
          log_and_ping('LSA Complete')
        ensure
          remove_temporary_rds()
        end
        finish_report()
      else
        log_and_ping('No LSA Report Queued')
      end
    end

    def log_and_ping msg
      msg = "#{msg} (ReportResult: #{@report&.id}, percent_complete: #{@report&.percent_complete})"
      Rails.logger.info msg
      @notifier.ping(msg) if @send_notifications
    end

    def sql_server_identifier
      "#{ ENV.fetch('CLIENT')&.gsub(/[^0-9a-z]/i, '') }-#{ Rails.env }-LSA-#{@report.id}".downcase
    end

    def create_hmis_csv_export
      # debugging
      if @hmis_export_id && GrdaWarehouse::HmisExport.where(id: @hmis_export_id).exists?
        return GrdaWarehouse::HmisExport.find(@hmis_export_id)
      end

      # All LSA reports should have the same HMIS export scope, so reuse the file if available from today
      existing_export = GrdaWarehouse::HmisExport.order(created_at: :desc).limit(1).
        where(
          created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day,
          start_date: '2012-10-01',
          period_type: 3,
          directive: 2,
          hash_status:1,
          include_deleted: false,
        ).
        where("project_ids @> ?", @project_ids.to_json).
        where.not(file: nil)&.first
      return existing_export if existing_export.present?

      Exporters::HmisTwentyTwenty::Base.new(
        start_date: '2012-10-01', # using 10/1/2012 so we can determine continuous homelessness
        end_date: @report_end,
        projects: @project_ids,
        period_type: 3,
        directive: 2,
        hash_status:1,
        include_deleted: false,
        user_id: @report.user_id,
      ).export!
    end

    def setup_temporary_rds
      ::Rds.identifier = sql_server_identifier
      ::Rds.timeout = 60_000_000
      @rds = ::Rds.new
      @rds.setup!
    end

    def unzip_path
      File.join('var', 'lsa', @report.id.to_s)
    end

    def zip_path
      File.join(unzip_path, "#{@report.id.to_s}.zip")
    end

    def zip_report_folder
      files = Dir.glob(File.join(unzip_path, '*')).map{|f| File.basename(f)}
      Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        files.each do |file_name|
          zipfile.add(
            file_name,
            File.join(unzip_path, file_name)
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

    def remove_report_files
      FileUtils.rm_rf(unzip_path)
    end

    def populate_hmis_tables
      load 'lib/rds_sql_server/lsa/fy2019/hmis_sql_server.rb' # provides thin wrappers to all HMIS tables
      extract_path = @hmis_export.unzip_to(unzip_path)
      read_rows = 50_000
      HmisSqlServer.models_by_hud_filename.each do |file_name, klass|
        # Read the file in batches to avoid over RAM usage
        File.open(File.join(extract_path, file_name)) do |file|
          headers = file.first
          file.lazy.each_slice(read_rows) do |lines|
            content = CSV.parse(lines.join, headers: headers)
            import_headers = content.first.headers
            if content.any?
              # this fixes dates that default to 1900-01-01 if you send an empty string
              content = content.map do |row|
                row = klass.new.clean_row_for_import(row: row.fields, headers: import_headers)
              end
              insert_batch(klass, import_headers, content, batch_size: 1_000)
            end
          end
        end
      end
      FileUtils.rm_rf(extract_path)
    end

    def fetch_results
      load 'lib/rds_sql_server/lsa/fy2019/lsa_sql_server.rb'
      # Make note of completion time, LSA requirements are very specific that this should be the time the report was completed, not when it was initiated.
      # There will only ever be one of these.
      LsaSqlServer::LSAReport.update_all(ReportDate: Time.now)
      LsaSqlServer.models_by_filename.each do |filename, klass|
        path = File.join(unzip_path, filename)
        # for some reason the example files are quoted, except the LSA files, which are not
        force_quotes = ! klass.name.include?('LSA')
        CSV.open(path, "wb", force_quotes: force_quotes) do |csv|
          csv << klass.attribute_names
          klass.all.each do |item|
            row = []
            item.attributes.values.each do |m|
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
      end
      # puts LsaSqlServer.models_by_filename.values.map(&:count).inspect
    end

    def setup_lsa_report
      load 'lib/rds_sql_server/lsa/fy2019/lsa_sql_server.rb'
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
        LSAScope: @lsa_scope
      )
    end

    def remove_temporary_rds
      if @destroy_rds
        # If we didn't specify a specific host, turn off RDS
        # Otherwise, just drop the databse
        if ENV['LSA_DB_HOST'].blank?
          @rds&.terminate!
        else
          SqlServerBase.connection.execute (<<~SQL);
            drop database #{@rds.database}
          SQL
        end
      end
    end

    def setup_hmis_table_structure
      ::Rds.identifier = sql_server_identifier
      load 'lib/rds_sql_server/lsa/fy2019/hmis_sql_server.rb'
      HmisSqlServer.models_by_hud_filename.each do |_, klass|
        klass.hmis_table_create!(version: '2020')
        klass.hmis_table_create_indices!(version: '2020')
      end
    end

    def setup_lsa_table_indexes
      SqlServerBase.connection.execute (<<~SQL);
        if not exists (select * from sys.indexes where name = 'ref_Populations_HHType_idx')
        begin
          create index ref_Populations_HHType_idx ON [ref_Populations] ([HHType]);
        end
        if not exists (select * from sys.indexes where name = 'ref_Populations_HHAdultAge_idx')
        begin
          create index ref_Populations_HHAdultAge_idx ON [ref_Populations] ([HHAdultAge]);
        end
        if not exists (select * from sys.indexes where name = 'ref_Populations_HHVet_idx')
        begin
          create index ref_Populations_HHVet_idx ON [ref_Populations] ([HHVet]);
        end
        if not exists (select * from sys.indexes where name = 'ref_Populations_HHDisability_idx')
        begin
          create index ref_Populations_HHDisability_idx ON [ref_Populations] ([HHDisability]);
        end
        if not exists (select * from sys.indexes where name = 'ref_Populations_HHChronic_idx')
        begin
          create index ref_Populations_HHChronic_idx ON [ref_Populations] ([HHChronic]);
        end
        if not exists (select * from sys.indexes where name = 'ref_Populations_HHFleeingDV_idx')
        begin
          create index ref_Populations_HHFleeingDV_idx ON [ref_Populations] ([HHFleeingDV]);
        end
        if not exists (select * from sys.indexes where name = 'ref_Populations_HHParent_idx')
        begin
          create index ref_Populations_HHParent_idx ON [ref_Populations] ([HHParent]);
        end
        if not exists (select * from sys.indexes where name = 'ref_Populations_HHChild_idx')
        begin
          create index ref_Populations_HHChild_idx ON [ref_Populations] ([HHChild]);
        end
        if not exists (select * from sys.indexes where name = 'ref_Populations_Stat_idx')
        begin
          create index ref_Populations_Stat_idx ON [ref_Populations] ([Stat]);
        end
        if not exists (select * from sys.indexes where name = 'ref_Populations_PSHMoveIn_idx')
        begin
          create index ref_Populations_PSHMoveIn_idx ON [ref_Populations] ([PSHMoveIn]);
        end
        if not exists (select * from sys.indexes where name = 'ref_Populations_HoHRace_idx')
        begin
          create index ref_Populations_HoHRace_idx ON [ref_Populations] ([HoHRace]);
        end
        if not exists (select * from sys.indexes where name = 'ref_Populations_HoHEthnicity_idx')
        begin
          create index ref_Populations_HoHEthnicity_idx ON [ref_Populations] ([HoHEthnicity]);
        end

        if not exists (select * from sys.indexes where name = 'active_Enrollment_PersonalID_idx')
        begin
          create index active_Enrollment_PersonalID_idx ON [active_Enrollment] ([PersonalID]);
        end
        if not exists (select * from sys.indexes where name = 'active_Enrollment_HouseholdID_idx')
        begin
          create index active_Enrollment_HouseholdID_idx ON [active_Enrollment] ([HouseholdID]);
        end
        if not exists (select * from sys.indexes where name = 'active_Enrollment_EntryDate_idx')
        begin
          create index active_Enrollment_EntryDate_idx ON [active_Enrollment] ([EntryDate]);
        end
        if not exists (select * from sys.indexes where name = 'active_Enrollment_ProjectType_idx')
        begin
          create index active_Enrollment_ProjectType_idx ON [active_Enrollment] ([ProjectType]);
        end
        if not exists (select * from sys.indexes where name = 'active_Enrollment_ProjectID_idx')
        begin
          create index active_Enrollment_ProjectID_idx ON [active_Enrollment] ([ProjectID]);
        end
        if not exists (select * from sys.indexes where name = 'active_Enrollment_RelationshipToHoH_idx')
        begin
          create index active_Enrollment_RelationshipToHoH_idx ON [active_Enrollment] ([RelationshipToHoH]);
        end

        if not exists (select * from sys.indexes where name = 'active_Household_HouseholdID_idx')
        begin
          create index active_Household_HouseholdID_idx ON [active_Household] ([HouseholdID]);
        end
        if not exists (select * from sys.indexes where name = 'active_Household_HoHID_idx')
        begin
          create index active_Household_HoHID_idx ON [active_Household] ([HoHID]);
        end
        if not exists (select * from sys.indexes where name = 'active_Household_HHType_idx')
        begin
          create index active_Household_HHType_idx ON [active_Household] ([HHType]);
        end

        if not exists (select * from sys.indexes where name = 'tmp_Household_HoHID_idx')
        begin
          create index tmp_Household_HoHID_idx ON [tmp_Household] ([HoHID]);
        end
        if not exists (select * from sys.indexes where name = 'tmp_Household_HHType_idx')
        begin
          create index tmp_Household_HHType_idx ON [tmp_Household] ([HHType]);
        end

        if not exists (select * from sys.indexes where name = 'tmp_Person_CHStart_idx')
        begin
          create index tmp_Person_CHStart_idx ON [tmp_Person] ([CHStart]);
        end
        if not exists (select * from sys.indexes where name = 'tmp_Person_LastActive_idx')
        begin
          create index tmp_Person_LastActive_idx ON [tmp_Person] ([LastActive]);
        end
        if not exists (select * from sys.indexes where name = 'tmp_Person_PersonalID_idx')
        begin
          create index tmp_Person_PersonalID_idx ON [tmp_Person] ([PersonalID]);
        end

        if not exists (select * from sys.indexes where name = 'ch_Enrollment_PersonalID_idx')
        begin
          create index ch_Enrollment_PersonalID_idx ON [ch_Enrollment] ([PersonalID]);
        end
        if not exists (select * from sys.indexes where name = 'ch_Enrollment_EnrollmentID_idx')
        begin
          create index ch_Enrollment_EnrollmentID_idx ON [ch_Enrollment] ([EnrollmentID]);
        end
        if not exists (select * from sys.indexes where name = 'ch_Enrollment_StartDate_idx')
        begin
          create index ch_Enrollment_StartDate_idx ON [ch_Enrollment] ([StartDate]);
        end
        if not exists (select * from sys.indexes where name = 'ch_Enrollment_StopDate_idx')
        begin
          create index ch_Enrollment_StopDate_idx ON [ch_Enrollment] ([StopDate]);
        end
        if not exists (select * from sys.indexes where name = 'ch_Enrollment_ProjectType_idx')
        begin
          create index ch_Enrollment_ProjectType_idx ON [ch_Enrollment] ([ProjectType]);
        end

        if not exists (select * from sys.indexes where name = 'ch_Exclude_excludeDate_idx')
        begin
          create index ch_Exclude_excludeDate_idx ON [ch_Exclude] ([excludeDate]);
        end

        if not exists (select * from sys.indexes where name = 'ch_Episodes_PersonalID_idx')
        begin
          create index ch_Episodes_PersonalID_idx ON [ch_Episodes] ([PersonalID]);
        end

        if not exists (select * from sys.indexes where name = 'tmp_CohortDates_CohortStart_idx')
        begin
          create index tmp_CohortDates_CohortStart_idx ON [tmp_CohortDates] ([CohortStart]);
        end
        if not exists (select * from sys.indexes where name = 'tmp_CohortDates_CohortEnd_idx')
        begin
          create index tmp_CohortDates_CohortEnd_idx ON [tmp_CohortDates] ([CohortEnd]);
        end

        if not exists (select * from sys.indexes where name = 'ref_Calendar_theDate_idx')
        begin
          create index ref_Calendar_theDate_idx ON [ref_Calendar] ([theDate]);
        end

        if not exists (select * from sys.indexes where name = 'ch_Time_chDate_idx')
        begin
          create index ch_Time_chDate_idx ON [ch_Time] ([chDate]);
        end
        if not exists (select * from sys.indexes where name = 'ch_Time_PersonalID_idx')
        begin
          create index ch_Time_PersonalID_idx ON [ch_Time] ([PersonalID]);
        end

        if not exists (select * from sys.indexes where name = 'sys_Time_HoHID_idx')
        begin
          create index sys_Time_HoHID_idx ON [sys_Time] ([HoHID]);
        end
        if not exists (select * from sys.indexes where name = 'sys_Time_HHType_idx')
        begin
          create index sys_Time_HHType_idx ON [sys_Time] ([HHType]);
        end
        if not exists (select * from sys.indexes where name = 'sys_Time_sysDate_idx')
        begin
          create index sys_Time_sysDate_idx ON [sys_Time] ([sysDate]);
        end
        if not exists (select * from sys.indexes where name = 'sys_Time_sysStatus_idx')
        begin
          create index sys_Time_sysStatus_idx ON [sys_Time] ([sysStatus]);
        end

        if not exists (select * from sys.indexes where name = 'sys_Enrollment_EnrollmentID_idx')
        begin
          create index sys_Enrollment_EnrollmentID_idx ON [sys_Enrollment] ([EnrollmentID]);
        end
        if not exists (select * from sys.indexes where name = 'sys_Enrollment_HoHID_idx')
        begin
          create index sys_Enrollment_HoHID_idx ON [sys_Enrollment] ([HoHID]);
        end
        if not exists (select * from sys.indexes where name = 'sys_Enrollment_HHType_idx')
        begin
          create index sys_Enrollment_HHType_idx ON [sys_Enrollment] ([HHType]);
        end
        if not exists (select * from sys.indexes where name = 'sys_Enrollment_EntryDate_idx')
        begin
          create index sys_Enrollment_EntryDate_idx ON [sys_Enrollment] ([EntryDate]);
        end
        if not exists (select * from sys.indexes where name = 'sys_Enrollment_ProjectType_idx')
        begin
          create index sys_Enrollment_ProjectType_idx ON [sys_Enrollment] ([ProjectType]);
        end

      SQL
    end

    def setup_lsa_table_structure
      ::Rds.identifier = sql_server_identifier
      load 'lib/rds_sql_server/lsa/fy2019/lsa_table_structure.rb'
    end

    def run_lsa_queries
      ::Rds.identifier = sql_server_identifier
      ::Rds.timeout = 60_000_000
      load 'lib/rds_sql_server/lsa/fy2019/lsa_queries.rb'
      rep = LsaSqlServer::LSAQueries.new
      rep.project_ids = @project_ids unless @lsa_scope == 1 # Non-System wide

      # some setup
      rep.insert_projects

      # loop through the LSA queries
      report_steps = rep.steps
      # This starts at 30%, ends at 90%
      step_percent = 60.0 / rep.steps.count
      rep.steps.each_with_index do |step, i|
        percent = 30 + i * step_percent
        update_report_progress percent: percent.round(2)
        start_time = Time.current
        rep.run_query(step)
        end_time = Time.current
        seconds = ((end_time - start_time)/1.minute).round * 60
        log_and_ping("LSA Query #{step} complete in #{distance_of_time_in_words(seconds)}")
      end
    end

    # def fetch_summary_results
    #   load 'lib/rds_sql_server/lsa/fy2019/lsa_report_summary.rb'
    #   summary = LsaSqlServer::LSAReportSummary.new
    #   summary_data = summary.fetch_results
    #   people = {headers: summary_data.columns.first, data: summary_data.rows.first}
    #   enrollments = {headers: summary_data.columns.second, data: summary_data.rows.second}
    #   demographics = summary.fetch_demographics
    #   @report.results = {summary: {people: people, enrollments: enrollments, demographics: demographics}}
    #   @report.save
    # end
  end
end
