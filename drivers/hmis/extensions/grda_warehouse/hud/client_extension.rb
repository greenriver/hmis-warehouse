###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern

    included do
      has_many :custom_client_addresses, **Hmis::Hud::Base.hmis_relation(:PersonalID, 'CustomClientAddress'), inverse_of: :client

      def as_hmis
        Hmis::Hud::Client.find(id)
      end
    end
  end
end
