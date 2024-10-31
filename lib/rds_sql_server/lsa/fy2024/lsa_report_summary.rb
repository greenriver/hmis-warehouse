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
        UnduplicatedClient: 'Unique count of clients',
        AdultHoHEntry: 'Total count of enrollments for adults or heads of household',
        HouseholdEntry: 'Distinct household count',
        ClientEntry: 'Distinct count of enrollments',
        ClientExit: 'Distinct count of clients who exited',
        NoCoC: 'Count of enrollments missing Enrollment CoC',
        SSNNotProvided: 'Count of SSNs not provided',
        SSNMissingOrInvalid: 'Count of SSNs missing or invalid',
        ClientSSNNotUnique: 'Count of clients with non-unique, probably valid, SSNs',
        DistinctSSNValueNotUnique: 'Distinct count of clients with non-unique SSNs',
        RelationshipToHoH: 'Count of invalid relationship to HoHs',
        DisablingCond: 'Distinct count of enrollments with an invalid disability record',
        LivingSituation: 'Distinct count of enrollments with an invalid prior living situations',
        LengthOfStay: 'Distinct count of enrollments with an invalid length of stay',
        HomelessDate: 'Distinct count of enrollments with an invalid date to street ES/SH',
        TimesHomeless: 'Distinct count of enrollments with an invalid times homeless',
        MonthsHomeless: 'Distinct count of enrollments with an invalid months homeless',
        Destination: 'Distinct count of enrollments with invalid Destinations',
        NotOneHoH: 'Distinct count of households with an ivalid number of heads of household',
        MoveInDate: 'Count of HoH with a Move-in Date outside acceptable range',
      }
    end
  end
end
