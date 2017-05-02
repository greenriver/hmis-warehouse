module GrdaWarehouse::Report
  class Disability < Base
    self.table_name = :report_disabilities
    
    belongs :enrollment
    belongs :demographic   # source client
    belongs :client
    has_one :exit, through: :enrollment
  end
end