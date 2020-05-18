require '/app/lib/rds_sql_server/sql_server_base'
module LsaSqlServer
  class LSAReportSummary
    def fetch_summary
      {
        'Client Count' => LsaSqlServer::LSAPerson.pluck(:RowTotal).sum,
        'Household Count' => LsaSqlServer::LSAPerson.pluck(:RowTotal).sum,
      }
    end

    private def report_columns
      {
        UnduplicatedClient1: 'Unique Clients in 1 year cohort',
        UnduplicatedClient3: 'Unique Clients in 3 year cohort',
        UnduplicatedAdult1: 'Unique Adults in 1 year cohort',
        UnduplicatedAdult3: 'Unique Adults in 3 year cohort',
        AdultHoHEntry1: '',
        AdultHoHEntry3: '',
        ClientEntry1: '',
        ClientEntry3: '',
        ClientExit1: '',
        ClientExit3: '',
        Household1: '',
        Household3: '',
        HoHPermToPH1: '',
        HoHPermToPH3: '',

        NoCoC: '',
        SSNNotProvided: '',
        SSNMissingOrInvalid: '',
        ClientSSNNotUnique: '',
        DistinctSSNValueNotUnique: '',
        DOB1: '',
        DOB3: '',
        Gender1: '',
        Gender3: '',
        Race1: '',
        Race3: '',
        Ethnicity1: '',
        Ethnicity3: '',
        VetStatus1: '',
        VetStatus3: '',
        RelationshipToHoH1: '',
        RelationshipToHoH3: '',
        DisablingCond1: '',
        DisablingCond3: '',
        LivingSituation1: '',
        LivingSituation3: '',
        LengthOfStay1: '',
        LengthOfStay3: '',
        HomelessDate1: '',
        HomelessDate3: '',
        TimesHomeless1: 'Invalid Times Homeless 1 year cohort',
        TimesHomeless3: 'Invalid Times Homeless 3 year cohort',
        MonthsHomeless1: 'Invalid Months Homeless 1 year cohort',
        MonthsHomeless3: 'Invalid Months Homeless 3 year cohort',
        DV1: 'Invalid DV configuration 1 year cohort',
        DV3: 'Invalid DV configuration 3 year cohort',
        Destination1: 'Invalid Destination 1 year cohort',
        Destination3: 'Invalid Destination 3 year cohort',
        NotOneHoH1: 'Invalid number of Heads of Household 1 year cohort',
        NotOneHoH3: 'Invalid number of Heads of Household 3 year cohort',
        MoveInDate1: 'Move-in Dates outside acceptable range 1 year cohort',
        MoveInDate3: 'Move-in Dates outside acceptable range 3 year cohort',
      }
    end
  end
end
