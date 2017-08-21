module HealthCharts
  extend ActiveSupport::Concern
  included do

    def health_housing_stati
      case_management_notes.map do |form|
        first_section = form.answers[:sections].first
        if first_section.present?
          answer = form.answers[:sections].first[:questions].select do |question|
            question[:question] == "A-6. Where did you sleep last night?"
          end.first
          [form.collected_at, self.class.health_housing_positive_outcomes.include?(answer[:answer])]
        end
      end.compact.to_h
    end

    def self.health_housing_positive_outcomes
      [    
        #Doubling Up
        #Shelter
        #Street
        #Transitional Housing / Residential Treatment Program
        #Motel
        'Supportive Housing',
        'Housing with No Supports',
        'Assisted Living / Nursing Home / Rest Home',
        # Unknown
        # Other
      ]
    end

    def health_self_sufficiency_scores
      self_sufficiency_assessments.order(collected_at: :asc).map do |assessment|
        # these should only have one section at this time
        if assessment.answers[:sections].count > 0
          assessment.answers[:sections].first[:questions].select do |row|
            row[:question] == 'Total'
          end.map do |score|
            [assessment.collected_at, score[:answer].to_f.round]
          end
        end
      end.compact.flatten(1).to_h
    end

    def health_income_benefits_over_time
      source_income_benefits.order(InformationDate: :asc).map do |income|
        [income[:InformationDate], {
          total: (income[:TotalMonthlyIncome] || 0).to_i, 
          earned: (income[:EarnedAmount] || 0).to_i,
          number_of_non_earned_sources: (income.sources - [:Earned]).count,
        }]
      end.to_h
    end
  end
end