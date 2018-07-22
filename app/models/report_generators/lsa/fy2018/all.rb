# Some testing code:
# reload!; report_id = Reports::Lsa::Fy2018::All.last.id; ReportResult.where(report_id: report_id).last.update(percent_complete: 0); ReportGenerators::Lsa::Fy2018::All.new.run!
#
# Conversion notes:
# 1. Break table creation sections into their own methods
# 2. Move lSA reference tables from the end to before the lsa queries method
# 3. Break up the queries (submitting after each) to prevent timeouts (maybe increase timeout?)
#   Replace "/*"" with
#   "SQL
#    SqlServerBase.connection.execute (<<~SQL);
#    /*"
# 4. Remove insert statement for lsa_Report that starts with "INSERT [dbo].[lsa_Report]"

load 'lib/rds_sql_server/rds.rb'
load 'lib/rds_sql_server/sql_server_base.rb'
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
          setup_temporary_rds()
          setup_hmis_table_structure()
          setup_lsa_table_structure()
          setup_lsa_reference_tables()
          setup_lsa_table_indexes()

          setup_lsa_report()

          populate_hmis_tables()

          run_lsa_queries()
          fetch_results()
        ensure
          # remove_temporary_rds()
        end
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def sql_server_identifier
      "#{ ENV.fetch('CLIENT') }-#{ Rails.env }-LSA".downcase
    end

    def create_hmis_csv_export
      # debugging
      return GrdaWarehouse::HmisExport.find(56)

      Exporters::HmisSixOneOne::Base.new(
        start_date: @report_start,
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
      Rds.identifier = sql_server_identifier
      Rds.timeout = 600_000
      @rds = Rds.new
      @rds.setup!
    end

    def unzip_path
      File.join('var', 'lsa', @report.id.to_s)
    end

    def populate_hmis_tables
      load 'lib/rds_sql_server/hmis_sql_server.rb' # provides thin wrappers to all HMIS tables
      extract_path = @hmis_export.unzip_to(unzip_path)
      HmisSqlServer.models_by_hud_filename.each do |file_name, klass|
        arr_of_arrs = CSV.read(File.join(extract_path, file_name))
        headers = arr_of_arrs.first
        content = arr_of_arrs.drop(1)
        if content.any?
          # this fixes dates that default to 1900-01-01 if you send an empty string
          content.map! do |row|
            row.map! do |data|
              if data.present?
                data
              else
                nil
              end
            end
          end
          insert_batch(klass, headers, content)
        end
      end
      #TODO: Remove expanded files
    end

    def fetch_results
      load 'lib/rds_sql_server/lsa_sql_server.rb'

      puts LsaSqlServer.models_by_filename.values.map(&:count).inspect
      binding.pry
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
      @rds.terminate!
    end

    def setup_hmis_table_structure
      Rds.identifier = sql_server_identifier
      load 'app/models/report_generators/lsa/fy2018/hmis_table_structure.rb'
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
      SQL
    end


    def setup_lsa_reference_tables
      Rds.identifier = sql_server_identifier
      load 'app/models/report_generators/lsa/fy2018/lsa_reference_table_structure.rb'
    end

    def setup_lsa_table_structure
      Rds.identifier = sql_server_identifier
      load 'app/models/report_generators/lsa/fy2018/lsa_table_structure.rb'
    end



    def run_lsa_queries
      Rds.identifier = sql_server_identifier
      Rds.timeout = 600_000
      load 'app/models/report_generators/lsa/fy2018/lsa_queries.rb'
    end
  end
end
