module GrdaWarehouse::Report
  class IncomeBenefit < Base
    self.table_name = :report_income_benefits
    
    belongs :enrollment
    belongs :demographic   # source client
    belongs :client
    has_one :exit, through: :enrollment
  end
end