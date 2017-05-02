module GrdaWarehouse::Report
  class Exit < Base
    self.table_name = :report_exits

    belongs :enrollment
    belongs :client
    has_one :demographic, through: :enrollment   # source client
  end
end