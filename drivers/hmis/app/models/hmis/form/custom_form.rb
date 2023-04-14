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
    owner if assessment?
  end

  def assessment?
    owner_type == 'Hmis::Hud::CustomAssessment'
  end

  def intake?
    data_collection_stage == 1
  end

  def exit?
    data_collection_stage == 3
  end

  # Validate `values` purely based on FormDefinition validation requirements
  # @return [HmisError::Error] an array errors
  def collect_form_validations
    definition.validate_form_values(values)
  end

  # Validate related records using custom AR Validators
  # @return [HmisError::Error] an array errors
  def collect_record_validations(user: nil, household_members: nil)
    # Collect ActiveRecord validations (as HmisErrors)
    errors = form_processor.collect_active_record_errors
    # Collect validations on the Assessment Date (if this is an assessment form)
    if assessment?
      errors.push(*Hmis::Hud::Validators::CustomAssessmentValidator.validate_assessment_date(
        assessment,
        # Need to pass household members so we can validate based on their unpersisted entry/exit dates
        household_members: household_members,
      ))
    end

    # Collect errors from custom validator, in the context of this role
    role = definition.role
    form_processor.related_records.each do |record|
      validator = record.class.validators.find { |v| v.is_a?(Hmis::Hud::Validators::BaseValidator) }&.class
      errors.push(*validator.hmis_validate(record, user: user, role: role)) if validator.present?
    end

    errors.errors
  end

  # Pull out the Assessment Date from the values hash
  def find_assessment_date_from_values
    item = definition&.assessment_date_item
    return nil unless item.present? && values.present?

    date_string = values[item.link_id]
    return nil unless date_string.present?

    HmisUtil::Dates.safe_parse_date(date_string: date_string)
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
