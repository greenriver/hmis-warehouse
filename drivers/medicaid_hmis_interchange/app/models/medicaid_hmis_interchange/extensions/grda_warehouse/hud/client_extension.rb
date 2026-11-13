###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module MedicaidHmisInterchange
  module GrdaWarehouse::Hud::ClientExtension
    extend ActiveSupport::Concern

    included do
      has_one :external_health_id, class_name: 'MedicaidHmisInterchange::Health::ExternalId'
    end
  end
end
