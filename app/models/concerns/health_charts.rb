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
          if self.class.health_housing_outcomes.keys.include?(answer[:answer])
            [form.collected_at.to_date, self.class.health_housing_outcomes[answer[:answer].strip], answer[:answer]]
          end
          # [form.collected_at.to_date, self.class.health_housing_positive_outcomes.include?(answer[:answer]), answer[:answer]]

        end
      end.select{|_,_,answer| answer.present?}.map{|date,outcome,_| [date, outcome]}.to_h
    end

    def self.health_housing_bucket(answer)
      case answer
      when *health_housing_temporary_outcomes
        'Temporary Housing'
      when *health_housing_pemanent_outcomes
        'Permanent Housing'
      when *health_housing_negative_outcomes
        answer
      else
        nil
      end
    end

    def self.health_housing_positive_outcome?(answer)
      health_housing_positive_outcomes.include?(answer)
    end

    def self.health_housing_outcomes
      {
        'Street' => {
          score: 0,
          postitive: false,
          status: :street,
        },
        'Shelter' => {
          score: 1,
          postitive: false,
          status: :shelter,
        },
        'Doubling Up' =>  {
          score: 2,
          postitive: false,
          status: :doubling_up,
        },
        'Transitional Housing / Residential Treatment Program' => {
          score: 3,
          postitive: false,
          status: :temporary,
        },
        'Motel' => {
          score: 3,
          postitive: false,
          status: :temporary,
        },
        'Assisted Living / Nursing Home / Rest Home' => {
          score: 4,
          postitive: false,
          status: :permanent,
        },
        'Supportive Housing' => {
          score: 4,
          postitive: false,
          status: :permanent,
        },
        'Housing with No Supports' => {
          score: 4,
          postitive: false,
          status: :permanent,
        },
        # 'Unknown',
        # 'Other',
      }.freeze
    end

    def self.health_housing_temporary_outcomes
      health_housing_outcomes.select{|_,v| v[:status] == :temporary}.keys
    end

    def self.health_housing_pemanent_outcomes
      health_housing_outcomes.select{|_,v| v[:status] == :permanent}.keys
    end

    def self.health_housing_positive_outcomes
      health_housing_outcomes.select{|_,v| v[:positive]}.keys
    end

    def self.health_housing_negative_outcomes
      health_housing_outcomes.select{|_,v| ! v[:positive]}.keys
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
      sib_t = source_income_benefits.arel_table
      source_income_benefits.where(sib_t[:InformationDate].gt('2016-07-01')).order(InformationDate: :asc).map do |income|
        [income[:InformationDate], {
          total: (income[:TotalMonthlyIncome] || 0).to_i,
          earned: (income[:EarnedAmount] || 0).to_i,
          number_of_non_earned_sources: (income.sources - [:Earned]).count,
        }]
      end.to_h
    end
  end
end
