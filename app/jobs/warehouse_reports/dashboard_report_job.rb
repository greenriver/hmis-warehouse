###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class DashboardReportJob < BaseJob
    include ArelHelper

    queue_as :dashboard_active_report

    def perform report_type, sub_population
      klass = GrdaWarehouse::WarehouseReports::Dashboard::Base.sub_populations_by_type[report_type.to_sym][sub_population.to_sym]
      klass.new.run_and_save!
    end

    def log msg, underline: false
      return unless Rails.env.development?
      Rails.logger.info msg
      Rails.logger.info "="*msg.length if underline
    end


  end
end