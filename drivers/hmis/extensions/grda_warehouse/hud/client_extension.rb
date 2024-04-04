###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern

    included do
      has_many :custom_client_addresses, **Hmis::Hud::Base.hmis_relation(:PersonalID, 'CustomClientAddress'), inverse_of: :client
      has_many :hmis_custom_assessments, through: :enrollments
      has_many :hmis_source_custom_assessments, through: :source_enrollments, source: :hmis_custom_assessments
      has_many :custom_services, through: :source_enrollments

      def as_hmis
        Hmis::Hud::Client.find(id)
      end
    end
  end
end
