###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::CustomForm < ::GrdaWarehouseBase
  include Hmis::Hud::Concerns::HasEnums
  self.table_name = :CustomForms

  belongs_to :owner, polymorphic: true, optional: false
  belongs_to :definition, optional: false
  belongs_to :form_processor, dependent: :destroy, autosave: true
  validate :form_processor_is_valid

  after_initialize :initialize_form_processor, if: :new_record?

  scope :with_role, ->(role) do
    joins(:definition).where(definition: { role: Array.wrap(role) })
  end

  def assessment
    owner if owner_type == 'Hmis::Hud::CustomAssessment'
  end

  def intake?
    data_collection_stage == 1
  end

  def exit?
    data_collection_stage == 3
  end

  # Validate `values` purely based on FormDefinition validation requirements
  # @return [HmisError::Error] an array errors
  def collect_form_validations(ignore_warnings: false)
    validation_errors = definition.validate_form_values(values)
    return validation_errors.reject(&:warning?) if ignore_warnings

    validation_errors
  end

  # Validate related records using custom AR Validators
  # @return [HmisError::Error] an array errors
  def collect_record_validations(ignore_warnings: false, user: nil)
    # Collect ActiveRecord validations (as HmisErrors)
    errors = form_processor.collect_hmis_errors

    # Collect errors from custom validator, in the context of this role
    role = definition.role
    form_processor.related_records.each do |record|
      validator = record.class.validators.find { |v| v.is_a?(Hmis::Hud::Validators::BaseValidator) }&.class
      errors.push(*validator.hmis_validate(record, user: user, role: role)) if validator.present?
    end

    return errors.drop_warnings! if ignore_warnings

    errors.errors
  end

  private def initialize_form_processor
    self.form_processor = Hmis::Form::FormProcessor.new(custom_form: self)
  end

  # Pull up the errors from the assessment form_processor so we can see them (as opposed to validates_associated)
  private def form_processor_is_valid
    return if form_processor.valid?

    errors.merge!(form_processor.errors)
  end
end
