###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::CustomDataElementDefinition < Hmis::Hud::Base
  include Hmis::Hud::Concerns::HasEnums
  self.table_name = :CustomDataElementDefinitions

  FIELD_TYPES = [
    :float,
    :integer,
    :boolean,
    :string,
    :text,
    :date,
    :json,
  ].freeze

  SERVICE_OWNER_TYPES = ['Hmis::Hud::Service', 'Hmis::Hud::CustomService'].freeze

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :assessments
  belongs_to :custom_service_type, class_name: 'Hmis::Hud::CustomServiceType'
  has_many :values, class_name: 'Hmis::Hud::CustomDataElement', inverse_of: :data_element_definition, foreign_key: :data_element_definition_id

  validate :validate_service_type

  scope :for_type, ->(owner_type) do
    where(owner_type: owner_type)
  end

  scope :for_service_type, ->(custom_service_type_id) do
    where(cded_t[:custom_service_type_id].eq(nil).or(cded_t[:custom_service_type_id].eq(custom_service_type_id)))
  end

  use_enum_with_same_key :form_role_enum_map, FIELD_TYPES.map { |f| [f, f.to_s.humanize] }.to_h

  def validate_service_type
    return unless custom_service_type_id.present?

    errors.add(:custom_service_type_id, :invalid) unless SERVICE_OWNER_TYPES.include?(owner_type)
  end
end
