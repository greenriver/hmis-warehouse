###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceScanning::GrdaWarehouse
end

module ServiceScanning::GrdaWarehouse::Hud
  module ProjectExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      has_many :service_scanning_services, class_name: 'ServiceScanning::Service'
    end
  end
end
