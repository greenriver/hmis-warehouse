class Hmis::Hud::Validators::CustomAssessmentValidator < Hmis::Hud::Validators::BaseValidator
  IGNORED = [
    :ExportID,
    :DateCreated,
    :DateUpdated,
    # CE fields are not present on the custom assessment
    :AssessmentID,
    :AssessmentLocation,
    :AssessmentType,
    :AssessmentLevel,
    :PrioritizationStatus,
  ].freeze

  def configuration
    Hmis::Hud::CustomAssessment.hmis_configuration(version: '2022').except(*IGNORED)
  end
end
