###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa::Generators::Fy2022::TableConcern
  extend ActiveSupport::Concern

  def setup_hmis_table_structure
    ::Rds.identifier = sql_server_identifier unless Rds.static_rds?
    ::Rds.database = sql_server_database
    load 'lib/rds_sql_server/lsa/fy2022/hmis_sql_server.rb'
    HmisSqlServer.models_by_hud_filename.each do |_, klass|
      klass.hmis_table_create!(version: '2022')
      klass.hmis_table_create_indices!(version: '2022')
    end
  end

  def setup_lsa_table_structure
    ::Rds.identifier = sql_server_identifier unless Rds.static_rds?
    ::Rds.database = sql_server_database
    load 'lib/rds_sql_server/lsa/fy2022/lsa_table_structure.rb'
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
      load 'lib/rds_sql_server/lsa/fy2022/lsa_sql_server.rb'
      tables = LsaSqlServer.models_by_filename.values.map(&:table_name)
      tables += LsaSqlServer.intermediate_models_by_filename.values.map(&:table_name)
      tables -= [] # these already have identity columns
      tables.sort
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
end
