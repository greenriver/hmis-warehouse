require_relative '../../sql_server_base'
module LsaSqlServer
  module_function def models_by_filename
    {
      'Project.csv' => LsaSqlServer::Project,
      'Organization.csv' => LsaSqlServer::Organization,
      'Funder.csv' => LsaSqlServer::Funder,
      'ProjectCoC.csv' => LsaSqlServer::ProjectCoc,
      'Inventory.csv' => LsaSqlServer::Inventory,
      'LSAReport.csv' => LsaSqlServer::LSAReport,
      'LSAPerson.csv' => LsaSqlServer::LSAPerson,
      'LSAHousehold.csv' => LsaSqlServer::LSAHousehold,
      'LSAExit.csv' => LsaSqlServer::LSAExit,
      'LSACalculated.csv' => LsaSqlServer::LSACalculated,
    }.freeze
  end

  module_function def intermediate_models_by_filename
    {
      'ch_Episodes.csv' => LsaSqlServer::ChEpisodes,
      'ch_Exclude.csv' => LsaSqlServer::ChExclude,
      'ch_Include.csv' => LsaSqlServer::ChInclude,
      'dq_Enrollment.csv' => LsaSqlServer::DqEnrollment,
      'ref_Calendar.csv' => LsaSqlServer::RefCalendar,
      'ref_RowPopulations.csv' => LsaSqlServer::RefRowPopulations,
      'ref_RowValues.csv' => LsaSqlServer::RefRowValues,
      'ref_PopHHTypes.csv' => LsaSqlServer::RefPopHhTypes,
      'sys_Time.csv' => LsaSqlServer::SysTime,
      'sys_TimePadded.csv' => LsaSqlServer::SysTimePadded,
      'tlsa_CohortDates.csv' => LsaSqlServer::TlsaCohortDates,
      'tlsa_Enrollment.csv' => LsaSqlServer::TlsaEnrollment,
      'tlsa_Exit.csv' => LsaSqlServer::TlsaExit,
      'tlsa_HHID.csv' => LsaSqlServer::TlsaHHID,
      'tlsa_Household.csv' => LsaSqlServer::TlsaHousehold,
      'tlsa_Person.csv' => LsaSqlServer::TlsaPerson,
    }.freeze
  end

  class DbUp < SqlServerBase
    include ::HMIS::Structure::Base
    self.table_name = :db_up

    def self.csv_columns
      [
        :id,
        :status,
      ]
    end

    def self.hmis_configuration(*)
      {
        status: {
          type: :string,
        },
      }
    end
  end

  class LSAReport < SqlServerBase
    self.table_name = :lsa_Report
    include TsqlImport

    def self.csv_columns
      [
        :ReportID,
        :ReportDate,
        :ReportStart,
        :ReportEnd,
        :ReportCoC,
        :SoftwareVendor,
        :SoftwareName,
        :VendorContact,
        :VendorEmail,
        :LSAScope,
        :UnduplicatedClient1,
        :UnduplicatedClient3,
        :UnduplicatedAdult1,
        :UnduplicatedAdult3,
        :AdultHoHEntry1,
        :AdultHoHEntry3,
        :ClientEntry1,
        :ClientEntry3,
        :ClientExit1,
        :ClientExit3,
        :Household1,
        :Household3,
        :HoHPermToPH1,
        :HoHPermToPH3,
        :NoCoC,
        :SSNNotProvided,
        :SSNMissingOrInvalid,
        :ClientSSNNotUnique,
        :DistinctSSNValueNotUnique,
        :DOB1,
        :DOB3,
        :Gender1,
        :Gender3,
        :Race1,
        :Race3,
        :Ethnicity1,
        :Ethnicity3,
        :VetStatus1,
        :VetStatus3,
        :RelationshipToHoH1,
        :RelationshipToHoH3,
        :DisablingCond1,
        :DisablingCond3,
        :LivingSituation1,
        :LivingSituation3,
        :LengthOfStay1,
        :LengthOfStay3,
        :HomelessDate1,
        :HomelessDate3,
        :TimesHomeless1,
        :TimesHomeless3,
        :MonthsHomeless1,
        :MonthsHomeless3,
        :DV1,
        :DV3,
        :Destination1,
        :Destination3,
        :NotOneHoH1,
        :NotOneHoH3,
        :MoveInDate1,
        :MoveInDate3,
      ]
    end
  end

  class LSAHousehold < SqlServerBase
    self.table_name = :lsa_Household
    include TsqlImport

    def self.csv_columns
      [
        :RowTotal,
        :Stat,
        :ReturnTime,
        :HHType,
        :HHChronic,
        :HHVet,
        :HHDisability,
        :HHFleeingDV,
        :HoHRace,
        :HoHEthnicity,
        :HHAdult,
        :HHChild,
        :HHNoDOB,
        :HHAdultAge,
        :HHParent,
        :ESTStatus,
        :ESTGeography,
        :ESTLivingSit,
        :ESTDestination,
        :ESTChronic,
        :ESTVet,
        :ESTDisability,
        :ESTFleeingDV,
        :ESTAC3Plus,
        :ESTAdultAge,
        :ESTParent,
        :RRHStatus,
        :RRHMoveIn,
        :RRHGeography,
        :RRHLivingSit,
        :RRHDestination,
        :RRHPreMoveInDays,
        :RRHChronic,
        :RRHVet,
        :RRHDisability,
        :RRHFleeingDV,
        :RRHAC3Plus,
        :RRHAdultAge,
        :RRHParent,
        :PSHStatus,
        :PSHMoveIn,
        :PSHGeography,
        :PSHLivingSit,
        :PSHDestination,
        :PSHHousedDays,
        :PSHChronic,
        :PSHVet,
        :PSHDisability,
        :PSHFleeingDV,
        :PSHAC3Plus,
        :PSHAdultAge,
        :PSHParent,
        :ESDays,
        :THDays,
        :ESTDays,
        :RRHPSHPreMoveInDays,
        :RRHHousedDays,
        :SystemDaysNotPSHHoused,
        :SystemHomelessDays,
        :Other3917Days,
        :TotalHomelessDays,
        :SystemPath,
        :ESTAHAR,
        :RRHAHAR,
        :PSHAHAR,
        :ReportID,
      ]
    end
  end

  class LSAPerson < SqlServerBase
    self.table_name = :lsa_Person
    include TsqlImport

    def self.csv_columns
      [
        :RowTotal,
        :Gender,
        :Race,
        :Ethnicity,
        :VetStatus,
        :DisabilityStatus,
        :CHTime,
        :CHTimeStatus,
        :DVStatus,
        :ESTAgeMin,
        :ESTAgeMax,
        :HHTypeEST,
        :HoHEST,
        :AdultEST,
        :HHChronicEST,
        :HHVetEST,
        :HHDisabilityEST,
        :HHFleeingDVEST,
        :HHAdultAgeAOEST,
        :HHAdultAgeACEST,
        :HHParentEST,
        :AC3PlusEST,
        :AHAREST,
        :AHARHoHEST,
        :RRHAgeMin,
        :RRHAgeMax,
        :HHTypeRRH,
        :HoHRRH,
        :AdultRRH,
        :HHChronicRRH,
        :HHVetRRH,
        :HHDisabilityRRH,
        :HHFleeingDVRRH,
        :HHAdultAgeAORRH,
        :HHAdultAgeACRRH,
        :HHParentRRH,
        :AC3PlusRRH,
        :AHARRRH,
        :AHARHoHRRH,
        :PSHAgeMin,
        :PSHAgeMax,
        :HHTypePSH,
        :HoHPSH,
        :AdultPSH,
        :HHChronicPSH,
        :HHVetPSH,
        :HHDisabilityPSH,
        :HHFleeingDVPSH,
        :HHAdultAgeAOPSH,
        :HHAdultAgeACPSH,
        :HHParentPSH,
        :AC3PlusPSH,
        :AHARPSH,
        :AHARHoHPSH,
        :AHARAdultPSH,
        :ReportID,
      ]
    end
  end

  class LSAExit < SqlServerBase
    self.table_name = :lsa_Exit
    include TsqlImport

    def self.csv_columns
      [
        :RowTotal,
        :Cohort,
        :Stat,
        :ExitFrom,
        :ExitTo,
        :ReturnTime,
        :HHType,
        :HHVet,
        :HHChronic,
        :HHDisability,
        :HHFleeingDV,
        :HoHRace,
        :HoHEthnicity,
        :HHAdultAge,
        :HHParent,
        :AC3Plus,
        :SystemPath,
        :ReportID,
      ]
    end
  end

  class LSACalculated < SqlServerBase
    self.table_name = :lsa_Calculated
    include TsqlImport

    def self.csv_columns
      [
        :Value,
        :Cohort,
        :Universe,
        :HHType,
        :Population,
        :SystemPath,
        :ProjectID,
        :ReportRow,
        :ReportID,
      ]
    end
  end

  class Organization < SqlServerBase
    self.table_name = :lsa_Organization
    include TsqlImport

    def self.csv_columns
      GrdaWarehouse::Hud::Organization.hud_csv_headers(version: '2022')
    end
  end

  class Project < SqlServerBase
    self.table_name = :lsa_Project
    include TsqlImport

    def self.csv_columns
      GrdaWarehouse::Hud::Project.hud_csv_headers(version: '2022')
    end
  end

  class Funder < SqlServerBase
    self.table_name = :lsa_Funder
    include TsqlImport

    def self.csv_columns
      GrdaWarehouse::Hud::Funder.hud_csv_headers(version: '2022')
    end
  end

  class Inventory < SqlServerBase
    self.table_name = :lsa_Inventory
    include TsqlImport

    def self.csv_columns
      GrdaWarehouse::Hud::Inventory.hud_csv_headers(version: '2022')
    end
  end

  class ProjectCoc < SqlServerBase
    self.table_name = :lsa_ProjectCoC
    include TsqlImport

    def self.csv_columns
      GrdaWarehouse::Hud::ProjectCoc.hud_csv_headers(version: '2022')
    end
  end

  class LSAHDXOnly < SqlServerBase
    self.table_name = :LSAHDXOnly
    include TsqlImport

    def self.csv_columns
      [
        :CHandDisability,
        :HHComposition,
      ]
    end
  end

  class LsaSqlServer::ChEpisodes < SqlServerBase
    self.table_name = :ch_Episodes
  end

  class LsaSqlServer::ChExclude < SqlServerBase
    self.table_name = :ch_Exclude
  end

  class LsaSqlServer::ChInclude < SqlServerBase
    self.table_name = :ch_Include
  end

  class LsaSqlServer::DqEnrollment < SqlServerBase
    self.table_name = :dq_Enrollment
  end

  class LsaSqlServer::RefCalendar < SqlServerBase
    self.table_name = :ref_Calendar

    def self.column_names
      [
        'theDate',
        'yyyy',
        'mm',
        'dd',
        'month_name',
        'day_name',
        'fy',
      ]
    end
  end

  class LsaSqlServer::RefRowPopulations < SqlServerBase
    self.table_name = :ref_RowPopulations
  end

  class LsaSqlServer::RefPopHhTypes < SqlServerBase
    self.table_name = :ref_PopHHTypes
  end

  class LsaSqlServer::RefRowValues < SqlServerBase
    self.table_name = :ref_RowValues
  end

  class LsaSqlServer::SysTime < SqlServerBase
    self.table_name = :sys_Time
  end

  class LsaSqlServer::SysTimePadded < SqlServerBase
    self.table_name = :sys_TimePadded
  end

  class LsaSqlServer::TlsaCohortDates < SqlServerBase
    self.table_name = :tlsa_CohortDates
  end

  class LsaSqlServer::TlsaEnrollment < SqlServerBase
    self.table_name = :tlsa_Enrollment
  end

  class LsaSqlServer::TlsaExit < SqlServerBase
    self.table_name = :tlsa_Exit
  end

  class LsaSqlServer::TlsaHHID < SqlServerBase
    self.table_name = :tlsa_HHID
  end

  class LsaSqlServer::TlsaHousehold < SqlServerBase
    self.table_name = :tlsa_Household
  end

  class LsaSqlServer::TlsaPerson < SqlServerBase
    self.table_name = :tlsa_Person
  end
end
