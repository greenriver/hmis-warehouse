class GrdaWarehouse::ServiceHistoryService < GrdaWarehouseBase
  include ArelHelper
  include ServiceHistoryServiceConcern

  belongs_to :service_history_enrollment, inverse_of: :service_history_services

  scope :hud_project_type, -> (project_types) do
    where(project_type: project_types)
  end

  def self.project_type_column
    :project_type
  end

  def self.sub_tables
    @table_name ||= table_years.map do |year|
      [year, "service_history_services_#{year}"]
    end.reverse.to_h
  end

  def self.remainder_table
    :service_history_services_remainder
  end

  def self.table_years
    (2000..2050)
  end

  def self.parent_table
    :service_history_services
  end
end