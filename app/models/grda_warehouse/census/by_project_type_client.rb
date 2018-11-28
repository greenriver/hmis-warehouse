module GrdaWarehouse::Census
  class ByProjectTypeClient < Base
    self.table_name = "nightly_census_by_project_type_clients"

    scope :for_date_range, -> (start_date, end_date) do
      where(date: start_date.to_date .. end_date.to_date).order(:date)
    end

  end
end
