module ServiceScanning::GrdaWarehouse
end
module ServiceScanning::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      has_many :service_scanning_scanner_ids, class_name: 'ServiceScanning::ScannerId'
      has_many :service_scanning_services, class_name: 'ServiceScanning::Service'

      def service_scanning_bed_nights_or_outreach?
        service_scanning_services.bed_nights_or_outreach.exists?
      end

      def unique_service_scanning_bed_nights
        ss_t = ServiceScanning::Service.arel_table
        service_scanning_services.bed_night.distinct.pluck(nf('DATE_TRUNC', ['day', ss_t[:provided_at]]))
      end

      def unique_service_scanning_outreach
        ss_t = ServiceScanning::Service.arel_table
        service_scanning_services.outreach.distinct.pluck(nf('DATE_TRUNC', ['day', ss_t[:provided_at]]))
      end
    end
  end
end
