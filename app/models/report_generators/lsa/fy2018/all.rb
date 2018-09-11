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
    def run!
      # Disable logging so we don't fill the disk
      # ActiveRecord::Base.logger.silence do
        calculate()
        Rails.logger.info "Done"
      # end # End silence ActiveRecord Log
    end

    private

    def calculate
      if start_report(Reports::Lsa::Fy2018::All.first)
        setup_filters()
        @report_start ||= @report.options['report_start'].to_date
        @report_end ||= @report.options['report_end'].to_date
        Rails.logger.info "Starting report #{@report.report.name}"
        begin
          @hmis_export = create_hmis_csv_export()
          update_report_progress percent: 15
          # puts 'done exporting'
          setup_temporary_rds()
          update_report_progress percent: 20
          # puts 'RDS setup done'
          setup_hmis_table_structure()
          setup_lsa_table_structure()
          setup_lsa_reference_tables()
          setup_lsa_table_indexes()

          update_report_progress percent: 22
          setup_lsa_report()

          populate_hmis_tables()
          update_report_progress percent: 30

          run_lsa_queries()
          update_report_progress percent: 90
          fetch_results()
          fetch_summary_results()
          zip_report_folder()
          attach_report_zip()
          remove_report_files()
        ensure
          remove_temporary_rds()
        end
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def sql_server_identifier
      "#{ ENV.fetch('CLIENT') }-#{ Rails.env }-LSA-#{@report.id}".downcase
    end

    def create_hmis_csv_export
      # debugging
      # return GrdaWarehouse::HmisExport.find(18)

      Exporters::HmisSixOneOne::Base.new(
        start_date: '2012-10-01', # @report_end # using 10/1/2012 so we can determine continuous homelessness
        end_date: @report_end,
        projects: @project_ids,
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
      read_rows = 10_000
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
              insert_batch(klass, import_headers, content, batch_size: 1000)
            end
          end
        end
      end
      FileUtils.rm_rf(extract_path)
    end

    def fetch_results
      load 'lib/rds_sql_server/lsa_sql_server.rb'
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
      # INSERT [dbo].[lsa_Report] ([ReportID], [ReportDate], [ReportStart], [ReportEnd], [ReportCoC], [SoftwareVendor], [SoftwareName], [VendorContact], [VendorEmail], [LSAScope]) VALUES (1009, CAST(N'2018-05-07T17:47:35.977' AS DateTime), CAST(N'2016-10-01' AS Date), CAST(N'2017-09-30' AS Date), N'XX-500', N'Tamale Inc.', N'Tamale Online', N'Molly', N'molly@squarepegdata.com', 1)
    end

    def remove_temporary_rds
      @rds&.terminate! unless Rails.env.development?
    end

    def setup_hmis_table_structure
      ::Rds.identifier = sql_server_identifier
      load 'lib/rds_sql_server/lsa/fy2018/hmis_table_structure.rb'
    end

    def setup_lsa_table_indexes
      SqlServerBase.connection.execute (<<~SQL);
        create index ref_populations_HHType_idx ON [ref_Populations] ([HHType]);
        create index ref_populations_HHAdultAge_idx ON [ref_Populations] ([HHAdultAge]);
        create index ref_populations_HHVet_idx ON [ref_Populations] ([HHVet]);
        create index ref_populations_HHDisability_idx ON [ref_Populations] ([HHDisability]);
        create index ref_populations_HHChronic_idx ON [ref_Populations] ([HHChronic]);
        create index ref_populations_HHFleeingDV_idx ON [ref_Populations] ([HHFleeingDV]);
        create index ref_populations_HHParent_idx ON [ref_Populations] ([HHParent]);
        create index ref_populations_HHChild_idx ON [ref_Populations] ([HHChild]);
        create index ref_populations_Stat_idx ON [ref_Populations] ([Stat]);
        create index ref_populations_PSHMoveIn_idx ON [ref_Populations] ([PSHMoveIn]);
        create index ref_populations_HoHRace_idx ON [ref_Populations] ([HoHRace]);
        create index ref_populations_HoHEthnicity_idx ON [ref_Populations] ([HoHEthnicity]);

        create index active_enrollment_personal_id_idx ON [active_Enrollment] ([PersonalID]);
        create index active_enrollment_household_id_idx ON [active_Enrollment] ([HouseholdID]);
        create index active_enrollment_entry_date_idx ON [active_Enrollment] ([EntryDate]);
        create index active_enrollment_project_type_idx ON [active_Enrollment] ([ProjectType]);
        create index active_enrollment_project_id_idx ON [active_Enrollment] ([ProjectID]);
        create index active_enrollment_relationship_to_hoh_idx ON [active_Enrollment] ([RelationshipToHoH]);

        create index active_household_household_id_idx ON [active_Household] ([HouseholdID]);
        create index active_household_ho_hid_idx ON [active_Household] ([HoHID]);
        create index active_household_hh_type_idx ON [active_Household] ([HHType]);

        create index ch_enrollment_personal_id_idx ON [ch_Enrollment] ([PersonalID]);

        create index ch_episodes_personal_id_idx ON [ch_Episodes] ([PersonalID]);

        create index tcd_start_date_idx ON [tmp_CohortDates] ([CohortStart]);
        create index tcd_end_date_idx ON [tmp_CohortDates] ([CohortEnd]);

        create index report_report_start_idx ON [lsa_Report] ([ReportStart]);
        create index report_report_end_idx ON [lsa_Report] ([ReportEnd]);
        create index report_report_report_coc_idx ON [lsa_Report] ([ReportCoC]);

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



    def run_lsa_queries
      ::Rds.identifier = sql_server_identifier
      ::Rds.timeout = 60_000_000
      load 'lib/rds_sql_server/lsa/fy2018/lsa_queries.rb'
    end

    def fetch_summary_results
      load 'lib/rds_sql_server/lsa_summary.rb'
      summary_data = LsaSqlServer::LSAReportSummary::fetch_results
      people = {headers: summary_data.columns.first, data: summary_data.rows.first}
      enrollments = {headers: summary_data.columns.second, data: summary_data.rows.second}
      @report.results = {summary: {people: people, enrollments: enrollments}}
      @report.save
    end
  end
end
