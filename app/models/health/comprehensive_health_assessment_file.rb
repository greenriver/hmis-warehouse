module Health
  class ComprehensiveHealthAssessmentFile < Health::HealthFile

    belongs_to :comprehensive_health_assessment, class_name: 'Health::ComprehensiveHealthAssessment', foreign_key: :parent_id

    def title
      'Comprehensive Health Assessment'
    end
  end
end