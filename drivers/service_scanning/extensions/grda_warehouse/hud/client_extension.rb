module ServiceScanning::GrdaWarehouse
end
module ServiceScanning::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      has_many :service_scanning_scanner_ids, class_name: 'ServiceScanning::ScannerId'
      has_many :service_scanning_services, class_name: 'ServiceScanning::Service'
    end
  end
end
