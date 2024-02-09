###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Concerns::HasCustomDataElements
  extend ActiveSupport::Concern

  included do
    has_many :custom_data_elements, as: :owner, dependent: :destroy
    has_many :custom_data_element_definitions, -> { distinct }, through: :custom_data_elements, source: :data_element_definition

    # Needed to support managing custom data elements via form processor
    accepts_nested_attributes_for :custom_data_elements, allow_destroy: true
  end
end
