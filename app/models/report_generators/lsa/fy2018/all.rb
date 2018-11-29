# Some testing code:
# Most recent LSA needs these options: Report Start: Oct 1, 2016; Report End: Sep 30, 2017; CoC-Code: XX-500
#
# reload!; report_id = Reports::Lsa::Fy2018::All.last.id; ReportResult.where(report_id: report_id).last.update(percent_complete: 0); ReportGenerators::Lsa::Fy2018::All.new.run!
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
if ENV['RDS_AWS_ACCESS_KEY_ID'].present?
  load 'lib/rds_sql_server/rds.rb'
  load 'lib/rds_sql_server/sql_server_base.rb'
end

module ReportGenerators::Lsa::Fy2018
  class All < Base
    include TsqlImport
    include NotifierConfig
    attr_accessor :send_notifications, :notifier_config
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
      if start_report(Reports::Lsa::Fy2018::All.first)
        setup_filters()
        @report_start ||= @report.options['report_start'].to_date
        @report_end ||= @report.options['report_end'].to_date
        Rails.logger.info "Starting report #{@report.report.name}"
        begin
          # error really early if we have issues with the sample code
          validate_lsa_sample_code()
          @hmis_export = create_hmis_csv_export()
          update_report_progress percent: 15
          log_and_ping('HMIS Export complete')
          # puts 'done exporting'
          setup_temporary_rds()
          update_report_progress percent: 20
          log_and_ping('RDS DB Setup')
          # puts 'RDS setup done'
          setup_hmis_table_structure()
          log_and_ping('HMIS Table Structure')
          setup_lsa_table_structure()
          log_and_ping('LSA Table Structure')
          setup_lsa_reference_tables()
          log_and_ping('LSA Reference Table Structure')
          setup_lsa_table_indexes()
          log_and_ping('LSA Indexes')

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
          fetch_summary_results()
          zip_report_folder()
          attach_report_zip()
          remove_report_files()
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
        ).where("project_ids @> ?", system_wide_project_ids.to_json)
        &.first
      return existing_export if existing_export.present?

      Exporters::HmisSixOneOne::Base.new(
        start_date: '2012-10-01', # using 10/1/2012 so we can determine continuous homelessness
        end_date: @report_end,
        projects: system_wide_project_ids,
        period_type: 3,
        directive: 2,
        hash_status:1,
        include_deleted: false,
        user_id: @report.user_id
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
      load 'lib/rds_sql_server/hmis_sql_server.rb' # provides thin wrappers to all HMIS tables
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
      load 'lib/rds_sql_server/lsa_sql_server.rb'
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
      load 'lib/rds_sql_server/lsa_sql_server.rb'
      LsaSqlServer::LSAReport.delete_all
      LsaSqlServer::LSAReport.create!(
        ReportID: Time.now.to_i,
        ReportDate: Date.today,
        ReportStart: @report_start,
        ReportEnd: @report_end,
        ReportCoC: @coc_code,
        SoftwareVendor: 'Green River Data Analysis',
        SoftwareName: 'OpenPath HMIS Data Warehouse',
        VendorContact: 'Elliot Anders',
        VendorEmail: 'elliot@greenriver.org',
        LSAScope: @lsa_scope
      )
      # INSERT [dbo].[lsa_Report] ([ReportID]
        # , [ReportDate], [ReportStart], [ReportEnd], [ReportCoC]
        # , [SoftwareVendor], [SoftwareName], [VendorContact], [VendorEmail]
        # , [LSAScope])
      # VALUES (1009
        # , CAST(N'2018-05-07T17:47:35.977' AS DateTime), CAST(N'2016-10-01' AS Date)
          # , CAST(N'2017-09-30' AS Date), N'XX-500'
        # , N'Tamale Inc.', N'Tamale Online', N'Molly', N'molly@squarepegdata.com'
        # , 1)
    end

    def remove_temporary_rds
      @rds&.terminate! if @destroy_rds
    end

    def setup_hmis_table_structure
      ::Rds.identifier = sql_server_identifier
      load 'lib/rds_sql_server/lsa/fy2018/hmis_table_structure.rb'
    end

    def setup_lsa_table_indexes
      SqlServerBase.connection.execute (<<~SQL);
        create index ref_Populations_HHType_idx ON [ref_Populations] ([HHType]);
        create index ref_Populations_HHAdultAge_idx ON [ref_Populations] ([HHAdultAge]);
        create index ref_Populations_HHVet_idx ON [ref_Populations] ([HHVet]);
        create index ref_Populations_HHDisability_idx ON [ref_Populations] ([HHDisability]);
        create index ref_Populations_HHChronic_idx ON [ref_Populations] ([HHChronic]);
        create index ref_Populations_HHFleeingDV_idx ON [ref_Populations] ([HHFleeingDV]);
        create index ref_Populations_HHParent_idx ON [ref_Populations] ([HHParent]);
        create index ref_Populations_HHChild_idx ON [ref_Populations] ([HHChild]);
        create index ref_Populations_Stat_idx ON [ref_Populations] ([Stat]);
        create index ref_Populations_PSHMoveIn_idx ON [ref_Populations] ([PSHMoveIn]);
        create index ref_Populations_HoHRace_idx ON [ref_Populations] ([HoHRace]);
        create index ref_Populations_HoHEthnicity_idx ON [ref_Populations] ([HoHEthnicity]);

        create index active_Enrollment_PersonalID_idx ON [active_Enrollment] ([PersonalID]);
        create index active_Enrollment_HouseholdID_idx ON [active_Enrollment] ([HouseholdID]);
        create index active_Enrollment_EntryDate_idx ON [active_Enrollment] ([EntryDate]);
        create index active_Enrollment_ProjectType_idx ON [active_Enrollment] ([ProjectType]);
        create index active_Enrollment_ProjectID_idx ON [active_Enrollment] ([ProjectID]);
        create index active_Enrollment_RelationshipToHoH_idx ON [active_Enrollment] ([RelationshipToHoH]);

        create index active_Household_HouseholdID_idx ON [active_Household] ([HouseholdID]);
        create index active_Household_HoHID_idx ON [active_Household] ([HoHID]);
        create index active_Household_HHType_idx ON [active_Household] ([HHType]);

        create index tmp_Household_HoHID_idx ON [tmp_Household] ([HoHID]);
        create index tmp_Household_HHType_idx ON [tmp_Household] ([HHType]);

        create index tmp_Person_CHStart_idx ON [tmp_Person] ([CHStart]);
        create index tmp_Person_LastActive_idx ON [tmp_Person] ([LastActive]);
        create index tmp_Person_PersonalID_idx ON [tmp_Person] ([PersonalID]);

        create index ch_Enrollment_PersonalID_idx ON [ch_Enrollment] ([PersonalID]);
        create index ch_Enrollment_EnrollmentID_idx ON [ch_Enrollment] ([EnrollmentID]);
        create index ch_Enrollment_StartDate_idx ON [ch_Enrollment] ([StartDate]);
        create index ch_Enrollment_StopDate_idx ON [ch_Enrollment] ([StopDate]);
        create index ch_Enrollment_ProjectType_idx ON [ch_Enrollment] ([ProjectType]);

        create index ch_Exclude_excludeDate_idx ON [ch_Exclude] ([excludeDate]);

        create index ch_Episodes_PersonalID_idx ON [ch_Episodes] ([PersonalID]);

        create index tmp_CohortDates_CohortStart_idx ON [tmp_CohortDates] ([CohortStart]);
        create index tmp_CohortDates_CohortEnd_idx ON [tmp_CohortDates] ([CohortEnd]);

        create index ref_Calendar_theDate_idx ON [ref_Calendar] ([theDate]);

        create index ch_Time_chDate_idx ON [ch_Time] ([chDate]);
        create index ch_Time_PersonalID_idx ON [ch_Time] ([PersonalID]);

        create index sys_Time_HoHID_idx ON [sys_Time] ([HoHID]);
        create index sys_Time_HHType_idx ON [sys_Time] ([HHType]);
        create index sys_Time_sysDate_idx ON [sys_Time] ([sysDate]);
        create index sys_Time_sysStatus_idx ON [sys_Time] ([sysStatus]);

        create index sys_Enrollment_EnrollmentID_idx ON [sys_Enrollment] ([EnrollmentID]);
        create index sys_Enrollment_HoHID_idx ON [sys_Enrollment] ([HoHID]);
        create index sys_Enrollment_HHType_idx ON [sys_Enrollment] ([HHType]);
        create index sys_Enrollment_EntryDate_idx ON [sys_Enrollment] ([EntryDate]);
        create index sys_Enrollment_ProjectType_idx ON [sys_Enrollment] ([ProjectType]);

      SQL
    end


    def setup_lsa_reference_tables
      ::Rds.identifier = sql_server_identifier
      load 'lib/rds_sql_server/lsa/fy2018/lsa_reference_table_structure.rb'
    end

    def setup_lsa_table_structure
      ::Rds.identifier = sql_server_identifier
      load 'lib/rds_sql_server/lsa/fy2018/lsa_table_structure.rb'
    end

    def validate_lsa_sample_code
      ::Rds.identifier = sql_server_identifier
      ::Rds.timeout = 60_000_000
      load 'lib/rds_sql_server/lsa/fy2018/lsa_queries.rb'
      rep.validate_file
    end

    def run_lsa_queries
      ::Rds.identifier = sql_server_identifier
      ::Rds.timeout = 60_000_000
      load 'lib/rds_sql_server/lsa/fy2018/lsa_queries.rb'
      if @lsa_scope == 1 # System wide
        rep = LsaSqlServer::LSAQueries.new
      else # Selected projects
        rep = LsaSqlServer::LSAQueries.new
        rep.project_ids = @project_ids
      end

      # some setup
      rep.clear
      rep.insert_projects

      # loop through the LSA queries
      report_steps = rep.steps
      # This starts at 30%, ends at 90%
      step_percent = 60.0 / rep.steps.count
      rep.steps.each_with_index do |step, i|
        percent = 30 + i * step_percent
        update_report_progress percent: percent.round(2)
        rep.run_query(step)
        log_and_ping("LSA Query #{step} complete")
      end
    end

    def fetch_summary_results
      load 'lib/rds_sql_server/lsa_summary.rb'
      summary = LsaSqlServer::LSAReportSummary.new
      summary_data = summary.fetch_results
      people = {headers: summary_data.columns.first, data: summary_data.rows.first}
      enrollments = {headers: summary_data.columns.second, data: summary_data.rows.second}
      demographics = summary.fetch_demographics
      @report.results = {summary: {people: people, enrollments: enrollments, demographics: demographics}}
      @report.save
    end


  end
end
