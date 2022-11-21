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
    end
  end
end
