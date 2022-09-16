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
        UnduplicatedClient: 'Unique Clients in 1 year cohort',
        AdultHoHEntry: 'Heads of Household in 1 year cohort',
        ClientEntry: 'Clients Entering in 1 year cohort',
        ClientExit: 'Clients Exiting in 1 year cohort',
        Household: 'Households in 1 year cohort',
        HoHPermToPH: 'Enrollments where HoH exited to a permanent destination, 1 year cohort',
        NoCoC: 'Enrollments missing EnrollmentCoC',
        SSNNotProvided: 'SSNs not provided',
        SSNMissingOrInvalid: 'SSNs missing or invalid',
        ClientSSNNotUnique: 'Clients with non-unique, probably valid, SSNs',
        DistinctSSNValueNotUnique: 'Count of non-unique SSNs',
        DOB: 'Missing DOBs in 1 year cohort',
        Gender: 'Invalid Genders in 1 year cohort',
        Race: 'Missing Race in 1 year cohort',
        Ethnicity: 'Invalid Ethnicities in 1 year cohort',
        VetStatus: 'Invalid Veteran Status in 1 year cohort',
        RelationshipToHoH: 'Invalid Relationship to HoHs in 1 year cohort',
        DisablingCond: 'Invalid Disabling Conditions in 1 year cohort',
        LivingSituation: 'Invalid Living Situations in 1 year cohort',
        LengthOfStay: 'Invalid Lengths of Stay in 1 year cohort',
        HomelessDate: 'Invalid Date to Street in 1 year cohort',
        TimesHomeless: 'Invalid Times Homeless 1 year cohort',
        MonthsHomeless: 'Invalid Months Homeless 1 year cohort',
        Destination: 'Invalid Destination 1 year cohort',
        NotOneHoH: 'Invalid number of Heads of Household 1 year cohort',
        MoveInDate: 'Move-in Dates outside acceptable range 1 year cohort',
      }
    end
  end
end
