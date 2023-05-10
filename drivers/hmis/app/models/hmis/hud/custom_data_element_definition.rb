###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# When loading form definition...
# Validate that custom field keys exist
# Validate that custom field types match (maybe)
class Hmis::Hud::CustomDataElementDefinition < Hmis::Hud::Base
  include Hmis::Hud::Concerns::HasEnums
  self.table_name = :CustomDataElementDefinitions

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :assessments
  has_many :values, class_name: 'Hmis::Hud::CustomDataElement', inverse_of: :data_element_definition, foreign_key: :data_element_definition_id

  FIELD_TYPES = [
    :float,
    :integer,
    :boolean,
    :string,
    :text,
    :date,
    :json,
  ].freeze

  use_enum_with_same_key :form_role_enum_map, FIELD_TYPES.map { |f| [f, f.to_s.humanize] }.to_h
end
