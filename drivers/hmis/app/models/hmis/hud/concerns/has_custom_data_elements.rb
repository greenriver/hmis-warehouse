###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Concerns::FormSubmittable
  extend ActiveSupport::Concern

  included do
    # throwing this in here because if you have CDEs you are most likely submittable via a form- maybe move to its own concern
    has_one :form_processor, class_name: 'Hmis::Form::FormProcessor', as: :owner, dependent: :destroy

    has_many :custom_data_elements, as: :owner, dependent: :destroy, class_name: 'Hmis::Hud::CustomDataElement'
    # All the CDEDs that have values for this record. Note it will retun non-distinct scope for any types that have multiple values.
    has_many :custom_data_element_definitions, through: :custom_data_elements, source: :data_element_definition, class_name: 'Hmis::Hud::CustomDataElementDefinition'

    # Needed to support managing custom data elements via form processor
    accepts_nested_attributes_for :custom_data_elements, allow_destroy: true
  end
end
