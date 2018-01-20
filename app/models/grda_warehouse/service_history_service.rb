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
end