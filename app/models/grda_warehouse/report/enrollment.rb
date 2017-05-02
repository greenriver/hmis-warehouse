# a view into enrollments
module GrdaWarehouse::Report
  class Enrollment < Base
    self.table_name = :report_enrollments

    belongs :demographic   # source client
    belongs :client
    many :health_and_dvs
    many :disabilities
    many :income_benefits
    many :employment_educations
    one :exit
  end
end