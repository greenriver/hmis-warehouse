###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Base < ::GrdaWarehouseBase
  self.abstract_class = true

  acts_as_paranoid(column: :DateDeleted)

  attr_writer :skip_validations
  attr_writer :required_fields

  scope :viewable_by, ->(_) do
    none
  end

  scope :editable_by, ->(_) do
    none
  end

  def self.hmis_relation(col, model_name = nil)
    h = {
      primary_key: [
        :data_source_id,
        col,
      ],
      foreign_key: [
        :data_source_id,
        col,
      ],
      autosave: false,
    }
    h.merge! class_name: "Hmis::Hud::#{model_name}" if model_name
    h
  end

  def self.generate_uuid
    SecureRandom.uuid.gsub(/-/, '')
  end

  # Fields that should be skipped during validation.
  def skip_validations
    @skip_validations ||= []
  end

  # Fields that should be validated as required during validation.
  # NOTE: No need to add fields here if they are not already required by the warehouse validator.
  def required_fields
    @required_fields ||= []
  end
end
