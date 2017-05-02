module GrdaWarehouse::Report
  class HealthAndDv < Base
    self.table_name = :report_health_and_dvs

    belongs :enrollment
    belongs :demographic   # source client
    belongs :client
    has_one :exit, through: :enrollment
  end
end