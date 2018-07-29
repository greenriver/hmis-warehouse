require_relative 'sql_server_base'
module LsaSqlServer

  module_function def models_by_filename
    {
      'LSAReport.csv' => LsaSqlServer::LSAReport,
      'LSAHousehold.csv' => LsaSqlServer::LSAHousehold,
      'LSAPerson.csv' => LsaSqlServer::LSAPerson,
      'LSAExit.csv' => LsaSqlServer::LSAExit,
      'LSACalculated.csv' => LsaSqlServer::LSACalculated,
      'Organization.csv' => LsaSqlServer::Organization,
      'Project.csv' => LsaSqlServer::Project,
      'Funder.csv' => LsaSqlServer::Funder,
      'Inventory.csv' => LsaSqlServer::Inventory,
      'Geography.csv' => LsaSqlServer::Geography,
      # 'LSAHDXOnly.csv' => LsaSqlServer::LSAHDXOnly,
    }.freeze
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
        :RRHStatus,
        :RRHMoveIn,
        :PSHStatus,
        :PSHMoveIn,
        :ESDays,
        :THDays,
        :ESTDays,
        :ESTGeography,
        :ESTLivingSit,
        :ESTDestination,
        :RRHPreMoveInDays,
        :RRHPSHPreMoveInDays,
        :RRHHousedDays,
        :SystemDaysNotPSHHoused,
        :RRHGeography,
        :RRHLivingSit,
        :RRHDestination,
        :SystemHomelessDays,
        :Other3917Days,
        :TotalHomelessDays,
        :PSHGeography,
        :PSHLivingSit,
        :PSHDestination,
        :PSHHousedDays,
        :SystemPath,
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
        :Age,
        :Gender,
        :Race,
        :Ethnicity,
        :VetStatus,
        :DisabilityStatus,
        :CHTime,
        :CHTimeStatus,
        :DVStatus,
        :HHTypeEST,
        :HoHEST,
        :HHTypeRRH,
        :HoHRRH,
        :HHTypePSH,
        :HoHPSH,
        :HHChronic,
        :HHVet,
        :HHDisability,
        :HHFleeingDV,
        :HHAdultAge,
        :HHParent,
        :AC3Plus,
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
      [
        :OrganizationID,
        :OrganizationName,
        :OrganizationCommonName,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    end
  end

  class Project < SqlServerBase
    self.table_name = :lsa_Project
    include TsqlImport

    def self.csv_columns
      [
        :ProjectID,
        :OrganizationID,
        :ProjectName,
        :ProjectCommonName,
        :OperatingStartDate,
        :OperatingEndDate,
        :ContinuumProject,
        :ProjectType,
        :ResidentialAffiliation,
        :TrackingMethod,
        :TargetPopulation,
        :VictimServicesProvider,
        :HousingType,
        :PITCount,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    end
  end

  class Funder < SqlServerBase
    self.table_name = :lsa_Funder
    include TsqlImport

    def self.csv_columns
      [
        :FunderID,
        :ProjectID,
        :Funder,
        :GrantID,
        :StartDate,
        :EndDate,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    end
  end

  class Inventory < SqlServerBase
    self.table_name = :lsa_Inventory
    include TsqlImport

    def self.csv_columns
      [
        :InventoryID,
        :ProjectID,
        :CoCCode,
        :InformationDate,
        :HouseholdType,
        :Availability,
        :UnitInventory,
        :BedInventory,
        :CHBedInventory,
        :VetBedInventory,
        :YouthBedInventory,
        :BedType,
        :InventoryStartDate,
        :InventoryEndDate,
        :HMISParticipatingBeds,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    end
  end

  class Geography < SqlServerBase
    self.table_name = :lsa_Geography
    include TsqlImport

    def self.csv_columns
      [
        :GeographyID,
        :ProjectID,
        :CoCCode,
        :InformationDate,
        :Geocode,
        :GeographyType,
        :Address1,
        :Address2,
        :City,
        :State,
        :ZIP,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
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
end