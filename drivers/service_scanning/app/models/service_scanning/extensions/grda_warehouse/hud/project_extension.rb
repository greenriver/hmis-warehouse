###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
