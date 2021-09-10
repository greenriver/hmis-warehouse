###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Testing:
# Testing is done manually against the sample data set since it requires spooling up an RDS installation.
# You can run: (This will re-use the most-recent result set, if you want to keep that, you should create a new one with the appropriate dates)
# @report = ReportResult.where(
#   report: Reports::Lsa::Fy2021::All.first,
# ).last;
# @report.update(percent_complete: 0, job_status: nil)
# r = ReportGenerators::Lsa::Fy2021::All.new(@report.options.merge(user_id: @report.user_id, test: false, destroy_rds: false))
# r.run!
# OR for a non-test run
# reload!; @report = ReportResult.where( report: Reports::Lsa::Fy2021::All.first, ).last; @report.update(percent_complete: 0, job_status: nil); r = ReportGenerators::Lsa::Fy2021::All.new(@report.options.merge(user_id: @report.user_id, test: false, destroy_rds: false)); r.run!

# This check is a proxy for all the vars you really need in the rds.rb file
# This if-statement prevents the lack of the vars from killing the app.

if ENV['RDS_AWS_ACCESS_KEY_ID'].present? && !ENV['NO_LSA_RDS'].present?
  load 'lib/rds_sql_server/rds.rb'
  load 'lib/rds_sql_server/sql_server_base.rb'
end

module ReportGenerators::Lsa::Fy2021
  class All < Base
    include TsqlImport
    include NotifierConfig
    include ActionView::Helpers::DateHelper
    attr_accessor :send_notifications, :notifier_config

    def initialize options
      @user = User.find(options[:user_id].to_i)
      selected_options = { options: options }

      destroy_rds = options.delete(:destroy_rds)
      selected_options.merge!(destroy_rds: destroy_rds) unless destroy_rds.nil?

      hmis_export_id = options.delete(:hmis_export_id)
      selected_options.merge!(hmis_export_id: hmis_export_id) if hmis_export_id

      super(selected_options)
    end

    def run!
      setup_notifier('LSA')
      # Disable logging so we don't fill the disk
      # ActiveRecord::Base.logger.silence do
      calculate
      Rails.logger.info 'Done Calculating LSA'
      # end # End silence ActiveRecord Log
    end

    # private

    def calculate
      if start_report(Reports::Lsa::Fy2021::All.first)
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

    def log_and_ping msg
      msg = "#{msg} (ReportResult: #{@report&.id}, percent_complete: #{@report&.percent_complete})"
      Rails.logger.info msg
      @notifier.ping(msg) if @send_notifications
    end

    def sql_server_identifier
      "#{ENV.fetch('CLIENT')&.gsub(/[^0-9a-z]/i, '')}-#{Rails.env}-LSA-#{@report.id}".downcase
    end

    def sql_server_database
      sql_server_identifier.underscore
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
        period_type: 3,
        directive: 2,
        hash_status: 1,
        include_deleted: false,
        user_id: @report.user_id,
      ).export!
      @report.export_id = @hmis_export.id
    end

    def setup_temporary_rds
      ::Rds.identifier = sql_server_identifier unless Rds.static_rds?
      ::Rds.database = sql_server_database
      ::Rds.timeout = 60_000_000
      @rds = ::Rds.new
      @rds.setup!
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

    # def zip_intermediate_report_folder
    #   files = Dir.glob(File.join(unzip_path, '*')).map { |f| File.basename(f) }
    #   Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
    #     files.each do |file_name|
    #       zipfile.add(
    #         file_name,
    #         File.join(unzip_path, file_name),
    #       )
    #     end
    #   end
    # end

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
      load 'lib/rds_sql_server/lsa/fy2021/hmis_sql_server.rb' # provides thin wrappers to all HMIS tables
      extract_path = if test?
        source = Rails.root.join('spec/fixtures/files/lsa/fy2021/sample_hmis_export/.')
        FileUtils.cp_r(source, unzip_path)
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
      load 'lib/rds_sql_server/lsa/fy2021/lsa_sql_server.rb'
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
      load 'lib/rds_sql_server/lsa/fy2021/lsa_sql_server.rb'
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
      load 'lib/rds_sql_server/lsa/fy2021/lsa_sql_server.rb'
      if test?
        ::Rds.identifier = sql_server_identifier unless Rds.static_rds?
        ::Rds.database = sql_server_database
        ::Rds.timeout = 60_000_000
        load 'lib/rds_sql_server/lsa/fy2021/lsa_queries.rb'
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

    def remove_temporary_rds
      return unless destroy_rds?

      # If we didn't specify a specific host, turn off RDS
      # Otherwise, just drop the database
      if ENV['LSA_DB_HOST'].blank?
        @rds&.terminate!
      else
        begin
          SqlServerBase.connection.execute(<<~SQL)
            use master
          SQL
          SqlServerBase.connection.execute(<<~SQL)
            drop database #{@rds.database}
          SQL
        rescue Exception => e
          puts e.inspect
        end
      end
    end

    def setup_hmis_table_structure
      ::Rds.identifier = sql_server_identifier unless Rds.static_rds?
      ::Rds.database = sql_server_database
      load 'lib/rds_sql_server/lsa/fy2021/hmis_sql_server.rb'
      HmisSqlServer.models_by_hud_filename.each do |_, klass|
        klass.hmis_table_create!(version: '2022')
        klass.hmis_table_create_indices!(version: '2022')
      end
    end

    def setup_lsa_table_indexes
      SqlServerBase.connection.execute(<<~SQL)
        if not exists (select * from sys.indexes where name = 'IX_sys_Time_sysStatus')
        begin
          CREATE INDEX [IX_sys_Time_sysStatus] ON [sys_Time] ([sysStatus])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Enrollment_HouseholdID')
        begin
          CREATE INDEX [IX_tlsa_Enrollment_HouseholdID] ON [tlsa_Enrollment] ([HouseholdID]) INCLUDE ([ActiveAge], [Exit1Age], [Exit2Age])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Enrollment_PersonalID_EntryDate_ExitDate')
        begin
          CREATE INDEX [IX_tlsa_Enrollment_PersonalID_EntryDate_ExitDate] ON [tlsa_Enrollment] ([PersonalID],[EntryDate], [ExitDate]) INCLUDE ([HouseholdID])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Enrollment_HouseholdID_EntryDate_ExitDate')
        begin
          CREATE INDEX [IX_tlsa_Enrollment_HouseholdID_EntryDate_ExitDate] ON [tlsa_Enrollment] ([HouseholdID],[EntryDate], [ExitDate])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Enrollment_HouseholdID_Active_ProjectType')
        begin
          CREATE INDEX [IX_tlsa_Enrollment_HouseholdID_Active_ProjectType] ON [tlsa_Enrollment] ([HouseholdID], [Active],[LSAProjectType]) INCLUDE ([PersonalID])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Enrollment_HouseholdID_EntryAge')
        begin
          CREATE INDEX [IX_tlsa_Enrollment_HouseholdID_EntryAge] ON [tlsa_Enrollment] ([HouseholdID],[EntryAge])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Enrollment_PersonalID_CH')
        begin
          CREATE INDEX [IX_tlsa_Enrollment_PersonalID_CH] ON [tlsa_Enrollment] ([PersonalID], [CH]) INCLUDE ([LSAProjectType])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Enrollment_EntryDate_ExitDate')
        begin
          CREATE INDEX [IX_tlsa_Enrollment_EntryDate_ExitDate] ON [tlsa_Enrollment] ([EntryDate], [ExitDate]) INCLUDE ([PersonalID], [EntryAge])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Enrollment_ProjectID')
        begin
          CREATE INDEX [IX_tlsa_Enrollment_ProjectID] ON [tlsa_Enrollment] ([ProjectID])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Enrollment_CH_ProjectType')
        begin
          CREATE INDEX [IX_tlsa_Enrollment_CH_ProjectType] ON [tlsa_Enrollment] ([CH],[LSAProjectType]) INCLUDE ([PersonalID], [EntryDate], [MoveInDate], [ExitDate])
        end
        -- if not exists(select * from sys.indexes where name = 'IX_tlsa_Enrollment_CH')
        -- begin
        --  CREATE INDEX [IX_tlsa_Enrollment_CH] ON [tlsa_Enrollment] ([CH]) INCLUDE ([PersonalID], [LSAProjectType], [TrackingMethod], [EntryDate], [ExitDate])
        -- end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Enrollment_Active')
        begin
          CREATE INDEX [IX_tlsa_Enrollment_Active] ON [tlsa_Enrollment] ([Active]) INCLUDE ([PersonalID], [HouseholdID], [EntryDate], [ExitDate])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_HoHID_ActiveHHType_Active')
        begin
          CREATE INDEX [IX_tlsa_HHID_HoHID_ActiveHHType_Active] ON [tlsa_HHID] ([HoHID], [ActiveHHType], [Active]) INCLUDE ([EnrollmentID], [ExitDest])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_Active_HHAdultAge')
        begin
          CREATE INDEX [IX_tlsa_HHID_Active_HHAdultAge] ON [tlsa_HHID] ([Active], [HHAdultAge]) INCLUDE ([HoHID], [ActiveHHType])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_HoHID_ProjectType_Exit2HHType_EntryDate_ExitDate')
        begin
          CREATE INDEX [IX_tlsa_HHID_HoHID_ProjectType_Exit2HHType_EntryDate_ExitDate] ON [tlsa_HHID] ([HoHID], [LSAProjectType], [Exit2HHType],[EntryDate], [ExitDate])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_HoHID_ActiveHHType_ProjectType_EntryDate_ExitDate')
        begin
          CREATE INDEX [IX_tlsa_HHID_HoHID_ActiveHHType_ProjectType_EntryDate_ExitDate] ON [tlsa_HHID] ([HoHID], [ActiveHHType],[LSAProjectType], [EntryDate], [ExitDate])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_HoHID_ExitDate')
        begin
          CREATE INDEX [IX_tlsa_HHID_HoHID_ExitDate] ON [tlsa_HHID] ([HoHID],[ExitDate]) INCLUDE ([ActiveHHType], [Exit1HHType], [Exit2HHType], [ExitDest])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_HoHID_Exit1HHType_ProjectType_EntryDate_ExitDate')
        begin
          CREATE INDEX [IX_tlsa_HHID_HoHID_Exit1HHType_ProjectType_EntryDate_ExitDate] ON [tlsa_HHID] ([HoHID], [Exit1HHType],[LSAProjectType], [EntryDate], [ExitDate])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_ProjectType')
        begin
          CREATE INDEX [IX_tlsa_HHID_ProjectType] ON [tlsa_HHID] ([LSAProjectType]) INCLUDE ([HoHID], [EntryDate], [ExitDate], [ActiveHHType], [Exit2HHType], [Exit1HHType], [MoveInDate])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_HoHID_ProjectType_Exit1HHType_EntryDate_ExitDate')
        begin
          CREATE INDEX [IX_tlsa_HHID_HoHID_ProjectType_Exit1HHType_EntryDate_ExitDate] ON [tlsa_HHID] ([HoHID], [LSAProjectType], [Exit1HHType],[EntryDate], [ExitDate])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_HoHID_Exit2HHType_ProjectType_EntryDate_ExitDate')
        begin
          CREATE INDEX [IX_tlsa_HHID_HoHID_Exit2HHType_ProjectType_EntryDate_ExitDate] ON [tlsa_HHID] ([HoHID], [Exit2HHType],[LSAProjectType], [EntryDate], [ExitDate])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_Active_EntryDate')
        begin
          CREATE INDEX [IX_tlsa_HHID_Active_EntryDate] ON [tlsa_HHID] ([Active],[EntryDate]) INCLUDE ([HoHID], [ActiveHHType], [HHChronic], [HHVet], [HHDisability], [HHFleeingDV], [HHParent])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_HoHID_ExitCohort')
        begin
          CREATE INDEX [IX_tlsa_HHID_HoHID_ExitCohort] ON [tlsa_HHID] ([HoHID], [ExitCohort])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_Active_ProjectType')
        begin
          CREATE INDEX [IX_tlsa_HHID_Active_ProjectType] ON [tlsa_HHID] ([Active],[LSAProjectType]) INCLUDE ([HoHID], [EntryDate], [MoveInDate], [ExitDate], [ActiveHHType])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_Active')
        begin
          CREATE INDEX [IX_tlsa_HHID_Active] ON [tlsa_HHID] ([Active]) INCLUDE ([HoHID], [EntryDate], [ActiveHHType], [HHChronic], [HHVet], [HHDisability], [HHFleeingDV], [HHParent])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_ExitCohort')
        begin
          CREATE INDEX [IX_tlsa_HHID_ExitCohort] ON [tlsa_HHID] ([ExitCohort]) INCLUDE ([HoHID], [EnrollmentID], [LSAProjectType], [EntryDate], [MoveInDate], [ActiveHHType], [Exit1HHType], [Exit2HHType], [ExitDest])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_SystemDaysNotPSHHoused')
        begin
          CREATE INDEX [IX_tlsa_Household_SystemDaysNotPSHHoused] ON [tlsa_Household] ([SystemDaysNotPSHHoused]) INCLUDE ([Stat], [HHChronic], [HHVet], [HHDisability], [HHFleeingDV], [HoHRace], [HoHEthnicity], [HHChild], [HHAdultAge], [HHParent], [PSHMoveIn], [SystemPath], [ReportID])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_SystemHomelessDays')
        begin
          CREATE INDEX [IX_tlsa_Household_SystemHomelessDays] ON [tlsa_Household] ([SystemHomelessDays]) INCLUDE ([Stat], [HHChronic], [HHVet], [HHDisability], [HHFleeingDV], [HoHRace], [HoHEthnicity], [HHChild], [HHAdultAge], [HHParent], [PSHMoveIn], [SystemPath], [ReportID])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_ESDays')
        begin
          CREATE INDEX [IX_tlsa_Household_ESDays] ON [tlsa_Household] ([ESDays]) INCLUDE ([Stat], [HHChronic], [HHVet], [HHDisability], [HHFleeingDV], [HoHRace], [HoHEthnicity], [HHChild], [HHAdultAge], [HHParent], [PSHMoveIn], [SystemPath], [ReportID])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_ESTDays')
        begin
          CREATE INDEX [IX_tlsa_Household_ESTDays] ON [tlsa_Household] ([ESTDays]) INCLUDE ([Stat], [HHChronic], [HHVet], [HHDisability], [HHFleeingDV], [HoHRace], [HoHEthnicity], [HHChild], [HHAdultAge], [HHParent], [PSHMoveIn], [SystemPath], [ReportID])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_TotalHomelessDays')
        begin
          CREATE INDEX [IX_tlsa_Household_TotalHomelessDays] ON [tlsa_Household] ([TotalHomelessDays]) INCLUDE ([Stat], [HHChronic], [HHVet], [HHDisability], [HHFleeingDV], [HoHRace], [HoHEthnicity], [HHChild], [HHAdultAge], [HHParent], [PSHMoveIn], [SystemPath], [ReportID])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_Other3917Days')
        begin
          CREATE INDEX [IX_tlsa_Household_Other3917Days] ON [tlsa_Household] ([Other3917Days]) INCLUDE ([Stat], [HHChronic], [HHVet], [HHDisability], [HHFleeingDV], [HoHRace], [HoHEthnicity], [HHChild], [HHAdultAge], [HHParent], [PSHMoveIn], [SystemPath], [ReportID])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_HHType_HHAdultAge')
        begin
          CREATE INDEX [IX_tlsa_Household_HHType_HHAdultAge] ON [tlsa_Household] ([HHType], [HHAdultAge])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_HHAdultAge')
        begin
          CREATE INDEX [IX_tlsa_Household_HHAdultAge] ON [tlsa_Household] ([HHAdultAge])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_LastInactive')
        begin
          CREATE INDEX [IX_tlsa_Household_LastInactive] ON [tlsa_Household] ([LastInactive])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_ESTStatus')
        begin
          CREATE INDEX [IX_tlsa_Household_ESTStatus] ON [tlsa_Household] ([ESTStatus])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_RRHMoveIn')
        begin
          CREATE INDEX [IX_tlsa_Household_RRHMoveIn] ON [tlsa_Household] ([RRHMoveIn]) INCLUDE ([Stat], [HHChronic], [HHVet], [HHDisability], [HHFleeingDV], [HoHRace], [HoHEthnicity], [HHChild], [HHAdultAge], [HHParent], [RRHStatus], [PSHMoveIn], [RRHHousedDays], [SystemPath], [ReportID])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_PSHStatus_PSHMoveIn')
        begin
          CREATE INDEX [IX_tlsa_Household_PSHStatus_PSHMoveIn] ON [tlsa_Household] ([PSHStatus], [PSHMoveIn]) INCLUDE ([Stat], [HHChronic], [HHVet], [HHDisability], [HHFleeingDV], [HoHRace], [HoHEthnicity], [HHChild], [HHAdultAge], [HHParent], [PSHHousedDays], [SystemPath], [ReportID])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_HHType_PSHStatus')
        begin
          CREATE INDEX [IX_tlsa_Household_HHType_PSHStatus] ON [tlsa_Household] ([HHType], [PSHStatus])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_RRHHousedDays')
        begin
          CREATE INDEX [IX_tlsa_Household_RRHHousedDays] ON [tlsa_Household] ([RRHHousedDays]) INCLUDE ([Stat], [HHChronic], [HHVet], [HHDisability], [HHFleeingDV], [HoHRace], [HoHEthnicity], [HHChild], [HHAdultAge], [HHParent], [PSHMoveIn], [SystemPath], [ReportID])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_THDays')
        begin
          CREATE INDEX [IX_tlsa_Household_THDays] ON [tlsa_Household] ([THDays]) INCLUDE ([Stat], [HHChronic], [HHVet], [HHDisability], [HHFleeingDV], [HoHRace], [HoHEthnicity], [HHChild], [HHAdultAge], [HHParent], [PSHMoveIn], [SystemPath], [ReportID])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_RRHPSHPreMoveInDays')
        begin
          CREATE INDEX [IX_tlsa_Household_RRHPSHPreMoveInDays] ON [tlsa_Household] ([RRHPSHPreMoveInDays]) INCLUDE ([Stat], [HHChronic], [HHVet], [HHDisability], [HHFleeingDV], [HoHRace], [HoHEthnicity], [HHChild], [HHAdultAge], [HHParent], [PSHMoveIn], [SystemPath], [ReportID])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_RRHStatus')
        begin
          CREATE INDEX [IX_tlsa_Household_RRHStatus] ON [tlsa_Household] ([RRHStatus]) INCLUDE ([Stat], [HHChronic], [HHVet], [HHDisability], [HHFleeingDV], [HoHRace], [HoHEthnicity], [HHChild], [HHAdultAge], [HHParent], [RRHMoveIn], [RRHPreMoveInDays], [PSHMoveIn], [SystemPath], [ReportID])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Household_HHType_RRHStatus')
        begin
          CREATE INDEX [IX_tlsa_Household_HHType_RRHStatus] ON [tlsa_Household] ([HHType], [RRHStatus])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_Person_CHTime')
        begin
          CREATE INDEX [IX_tlsa_Person_CHTime] ON [tlsa_Person] ([CHTime]) INCLUDE ([LastActive])
        end
        if not exists(select * from sys.indexes where name = 'IX_ch_Include_ESSHStreetDate')
        begin
          CREATE INDEX [IX_ch_Include_ESSHStreetDate] ON [ch_Include] ([ESSHStreetDate])
        end

        -- if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_TrackingMethod')
        -- begin
        --  CREATE INDEX [IX_tlsa_HHID_TrackingMethod] ON [tlsa_HHID] ([TrackingMethod]) INCLUDE ([HoHID], [EnrollmentID], [ExitDate], [ActiveHHType], [Active])
        -- end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_EnrollmentID')
        begin
          CREATE INDEX [IX_tlsa_HHID_EnrollmentID] ON [tlsa_HHID] ([EnrollmentID]) INCLUDE ([ExitDate], [ExitDest])
        end
        if not exists(select * from sys.indexes where name = 'IX_tlsa_HHID_Active')
        begin
          CREATE INDEX [IX_tlsa_HHID_Active] ON [tlsa_HHID] ([Active]) INCLUDE ([HoHID], [EnrollmentID], [ActiveHHType], [ExitDest])
        end
      SQL
    end

    def setup_lsa_table_structure
      ::Rds.identifier = sql_server_identifier unless Rds.static_rds?
      ::Rds.database = sql_server_database
      load 'lib/rds_sql_server/lsa/fy2021/lsa_table_structure.rb'
    end

    def run_lsa_queries
      ::Rds.identifier = sql_server_identifier unless Rds.static_rds?
      ::Rds.database = sql_server_database
      ::Rds.timeout = 60_000_000
      load 'lib/rds_sql_server/lsa/fy2021/lsa_queries.rb'
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
      load 'lib/rds_sql_server/lsa/fy2021/lsa_report_summary.rb'
      summary = LsaSqlServer::LSAReportSummary.new
      @report.results = { summary: summary.fetch_summary }
      @report.save
    end

    def add_missing_identity_columns
      query = ''
      tables_needing_identity_columns.each do |table_name|
        query += " ALTER TABLE #{table_name} ADD id BIGINT identity (1,1) NOT NULL; "
      end
      # Add some useful Identity columns
      SqlServerBase.connection.execute(query)
    end

    def remove_missing_identity_columns
      query = ''
      tables_needing_identity_columns.each do |table_name|
        query += " ALTER TABLE #{table_name} DROP COLUMN id; "
      end
      # Remove the useful Identity columns
      SqlServerBase.connection.execute(query)
    end

    def tables_needing_identity_columns
      @tables_needing_identity_columns ||= begin
        load 'lib/rds_sql_server/rds.rb'
        load 'lib/rds_sql_server/lsa/fy2021/lsa_sql_server.rb'
        tables = LsaSqlServer.models_by_filename.values.map(&:table_name)
        tables += LsaSqlServer.intermediate_models_by_filename.values.map(&:table_name)
        tables -= [] # these already have identity columns
        tables.sort
      end
    end
  end
end
