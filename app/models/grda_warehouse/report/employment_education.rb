module GrdaWarehouse::Report
  class EmploymentEducation < Base
    self.table_name = :report_employment_educations
    
    belongs :enrollment
    belongs :demographic   # source client
    belongs :client
    has_one :exit, through: :enrollment
  end
end