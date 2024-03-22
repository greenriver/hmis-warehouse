class HmisExternalApis::TcHmis::Importers::SyntheticCeAssessmentsForCustomAssessment
  def perform(custom_assessments:, assessment_type:, assessment_level:, prioritization_status:)
    default_attrs = {
      synthetic: true,
      AssessmentType: assessment_type,
      AssessmentLevel: assessment_level,
      PrioritizationStatus: prioritization_status,
    }
    prepared = custom_assessments.preload(enrollment: :project).preload(:form_processor)
    total = 0
    Hmis::Hud::Assessment.transaction do
      prepared.find_each do |custom_assessment|
        next if custom_assessment.form_processor.ce_assessment

        create_synthetic_ce_assessment(custom_assessment, default_attrs)
        total += 1
      end
    end
    total
  end

  protected

  def create_synthetic_ce_assessment(custom_assessment, default_attrs)
    project = custom_assessment.enrollment.project
    dup_attrs = custom_assessment.attributes.slice(
      'EnrollmentID',
      'PersonalID',
      'UserID',
      'AssessmentDate',
      'data_source_id',
      'DateCreated',
      'DateUpdated',
    )
    ce_assessment = Hmis::Hud::Assessment.create!(
      dup_attrs.merge(default_attrs).merge(AssessmentLocation: project.ProjectName),
    )
    puts ce_assessment.id
    custom_assessment.form_processor.update!(ce_assessment: ce_assessment)
  end
end
