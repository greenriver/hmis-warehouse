###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::GrdaWarehouse
  module DataSourceExtension
    extend ActiveSupport::Concern

    included do
      has_many :custom_data_element_definitions, class_name: 'Hmis::Hud::CustomDataElementDefinition'
    end
  end
end
