class GrdaWarehouse::ServiceHistoryService < GrdaWarehouseBase
  include ArelHelper
  belongs_to :service_history_enrollment, inverse_of: :service_history_services

  scope :service, -> { where record_type: service_types }
  scope :extrapolated, -> { where record_type: 'extrapolated' }

  def self.service_types
    service_types = ['service']
    if GrdaWarehouse::Config.get(:so_day_as_month)
      service_types << 'extrapolated'
    end
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