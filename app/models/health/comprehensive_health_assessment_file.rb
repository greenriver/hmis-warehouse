# ### HIPPA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented in base class
module Health
  class ComprehensiveHealthAssessmentFile < Health::HealthFile

    belongs_to :comprehensive_health_assessment, class_name: 'Health::ComprehensiveHealthAssessment', foreign_key: :parent_id

    def title
      'Comprehensive Health Assessment'
    end
  end
end