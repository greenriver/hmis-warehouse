class ReportingBase < ActiveRecord::Base
  establish_connection DB_REPORTING
  self.abstract_class = true
end
