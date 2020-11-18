require_relative '../../sql_server_base' unless ENV['NO_LSA_RDS'].present?
require_relative 'lsa_sql_server' unless ENV['NO_LSA_RDS'].present?
module LsaSqlServer
  class LSAReportSummary
    def fetch_summary
      rep = LsaSqlServer::LSAReport.first
      report_columns.map do |column, title|
        [
          title,
          rep[column],
        ]
      end.to_h
    end

    private def report_columns
      {
        UnduplicatedClient1: 'Unique Clients in 1 year cohort',
        UnduplicatedClient3: 'Unique Clients in 3 year cohort',
        UnduplicatedAdult1: 'Unique Adults in 1 year cohort',
        UnduplicatedAdult3: 'Unique Adults in 3 year cohort',
        AdultHoHEntry1: 'Heads of Household in 1 year cohort',
        AdultHoHEntry3: 'Heads of Household in 3 year cohort',
        ClientEntry1: 'Clients Entering in 1 year cohort',
        ClientEntry3: 'Clients Entering in 3 year cohort',
        ClientExit1: 'Clients Exiting in 1 year cohort',
        ClientExit3: 'Clients Exiting in 3 year cohort',
        Household1: 'Households in 1 year cohort',
        Household3: 'Households in 3 year cohort',
        HoHPermToPH1: 'Enrollments where HoH exited to a permanent destination, 1 year cohort',
        HoHPermToPH3: 'Enrollments where HoH exited to a permanent destination, 3 year cohort',

        NoCoC: 'Enrollments missing EnrollmentCoC',
        SSNNotProvided: 'SSNs not provided',
        SSNMissingOrInvalid: 'SSNs missing or invalid',
        ClientSSNNotUnique: 'Clients with non-unique, probably valid, SSNs',
        DistinctSSNValueNotUnique: 'Count of non-unique SSNs',
        DOB1: 'Missing DOBs in 1 year cohort',
        DOB3: 'Missing DOBs in 3 year cohort',
        Gender1: 'Invalid Genders in 1 year cohort',
        Gender3: 'Invalid Genders in 3 year cohort',
        Race1: 'Missing Race in 1 year cohort',
        Race3: 'Missing Race in 3 year cohort',
        Ethnicity1: 'Invalid Ethnicities in 1 year cohort',
        Ethnicity3: 'Invalid Ethnicities in 3 year cohort',
        VetStatus1: 'Invalid Veteran Status in 1 year cohort',
        VetStatus3: 'Invalid Veteran Status in 3 year cohort',
        RelationshipToHoH1: 'Invalid Relationship to HoHs in 1 year cohort',
        RelationshipToHoH3: 'Invalid Relationship to HoHs in 3 year cohort',
        DisablingCond1: 'Invalid Disabling Conditions in 1 year cohort',
        DisablingCond3: 'Invalid Disabling Conditions in 3 year cohort',
        LivingSituation1: 'Invalid Living Situations in 1 year cohort',
        LivingSituation3: 'Invalid Living Situations in 3 year cohort',
        LengthOfStay1: 'Invalid Lenghts of Stay in 1 year cohort',
        LengthOfStay3: 'Invalid Lenghts of Stay in 3 year cohort',
        HomelessDate1: 'Invalid Date to Street in 1 year cohort',
        HomelessDate3: 'Invalid Date to Street in 3 year cohort',
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
