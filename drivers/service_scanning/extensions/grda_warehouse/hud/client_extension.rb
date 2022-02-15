###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

      def unique_service_scanning_outreach(include_extrapolated: false)
        ss_t = ServiceScanning::Service.arel_table
        scanned_dates = service_scanning_services.outreach.distinct.pluck(nf('DATE_TRUNC', ['day', ss_t[:provided_at]]))
        return scanned_dates unless include_extrapolated

        all_dates = Set.new
        scanned_dates.each do |date|
          date = date.to_date
          all_dates += (date.beginning_of_month..date.end_of_month).to_a
        end
        all_dates
      end
    end
  end
end
