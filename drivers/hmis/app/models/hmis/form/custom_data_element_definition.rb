###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# When loading form definition...
# Validate that custom field keys exist
# Validate that custom field types match (maybe)
class Hmis::Form::CustomDataElementDefinition < ::GrdaWarehouseBase
  include Hmis::Hud::Concerns::HasEnums
  self.table_name = :CustomDataElementDefinitions

  has_many :values, class_name: 'Hmis::Form::CustomFormAnswer', inverse_of: :custom_data_element_definition

  FIELD_TYPES = [
    :string,
    :integer,
    :date,
    :boolean,
  ].freeze

  use_enum_with_same_key :form_role_enum_map, FIELD_TYPES.map { |f| [f, f.to_s.humanize] }.to_h
end
