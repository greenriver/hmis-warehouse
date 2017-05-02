module GrdaWarehouse::Report
  class Service < Base
    self.table_name = :report_services

    belongs :demographic   # source client
    belongs :client
  end
end