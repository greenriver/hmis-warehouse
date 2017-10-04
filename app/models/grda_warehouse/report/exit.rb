module GrdaWarehouse::Report
  class Exit < Base
    self.table_name = :report_exits

    belongs :enrollment
    belongs :client
    belongs :demographic
  end
end