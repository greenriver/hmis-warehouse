###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonService::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern

    included do
      has_many :custom_b_services, class_name: '::CustomImportsBostonService::Row', primary_key: [:PersonalID, :data_source_id], foreign_key: [:personal_id, :data_source_id]

      has_many :source_custom_b_services, through: :source_clients, source: :custom_b_services

      def source_non_event_custom_b_services_for_display
        # FIXME: I believe these need to be pre-processed but this should suffice for the short term
        source_custom_b_services.client_services.
          distinct.
          select(:date, :service_name, :agency_id, :data_source_id).
          order(date: :desc).
          preload(:organization)
      end
    end
  end
end
