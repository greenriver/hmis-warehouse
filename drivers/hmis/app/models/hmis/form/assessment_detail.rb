###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::AssessmentDetail < ::GrdaWarehouseBase
  include Hmis::Hud::Concerns::HasEnums
  self.table_name = :hmis_assessment_details
  belongs_to :assessment, class_name: 'Hmis::Hud::Assessment'
  belongs_to :definition
  belongs_to :assessment_processor, dependent: :destroy
  validate :assessment_processor_is_valid

  after_initialize :build_assessment_processor

  scope :with_role, ->(role) do
    where(role: Array.wrap(role))
  end

  def intake?
    data_collection_stage == 1
  end

  def exit?
    data_collection_stage == 3
  end

  # Pull up the errors from the assessment processor so we can see them (as opposed to validates_associated)
  private def assessment_processor_is_valid
    return if assessment_processor.valid?

    assessment_processor.errors.each do |error|
      errors.add(error.attribute, error.type, error.options)
    end
  end
end
