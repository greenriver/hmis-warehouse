###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Rename: CustomDataElement
class Hmis::Form::CustomFormAnswer < ::GrdaWarehouseBase
  include Hmis::Concerns::HmisArelHelper
  self.table_name = :CustomFormAnswers

  # belongs_to :definition, optional: false
  belongs_to :owner, polymorphic: true, optional: false
  belongs_to :custom_data_element_definition, optional: false

  # This should be optional...why do we need it? Maybe for assessments?
  belongs_to :form_processor, optional: false

  # Enforce that owner_type is correct for the Data Element Definition
  validate :validate_owner_types_match

  # Enforce the "repeats" value of the Custom Data Element Definition.
  # Some custom elements can have multiple values per record, for example "Primary Languages"
  # Other custom elements can only have one value per record, like "Move-in Date Comment"
  validates_uniqueness_of :owner_id,
                          scope: [:owner_type, :custom_data_element_definition_id],
                          conditions: -> { joins(:custom_data_element_definition).where(cded_t[:repeats].eq(false)) }

  def validate_owner_types_match
    errors.add(:owner_type, :invalid) if custom_data_element_definition.owner_type != owner_type
  end

  scope :of_type, ->(data_element_definition) do
    where(custom_data_element_definition: data_element_definition)
  end
end
