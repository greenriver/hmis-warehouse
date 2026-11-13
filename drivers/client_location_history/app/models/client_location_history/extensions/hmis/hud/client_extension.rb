###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ClientLocationHistory::Hmis::Hud
  module ClientExtension
    extend ActiveSupport::Concern

    included do
      has_many :client_location_histories, class_name: 'ClientLocationHistory::Location'
    end
  end
end
