module HealthCharts
  extend ActiveSupport::Concern
  included do

    def health_housing_stati
      stati = case_management_notes.map do |form|
        first_section = form.answers[:sections].first
        if first_section.present?
          answer = form.answers[:sections].first[:questions].select do |question|
            question[:question] == "A-6. Where did you sleep last night?"
          end.first[:answer]
          if self.class.health_housing_outcome(answer)
            {
              date: form.collected_at.to_date,
              score: self.class.health_housing_score(answer),
              status: answer
            }
          end
        end
      end.compact
      if patient.housing_status_timestamp.present?
        stati << {
          date: patient.housing_status_timestamp.to_date,
          score: self.class.health_housing_score(patient.housing_status),
          status: patient.housing_status,
        }
      end
      stati.sort_by{|m| m[:date]}
    end

    def self.health_housing_bucket(answer)
      case answer
      when *health_housing_temporary_outcomes
        'Temporary Housing'
      when *health_housing_permanent_outcomes
        'Permanent Housing'
      when *health_housing_negative_outcomes
        answer
      else
        nil
      end
    end

    def self.health_housing_outcomes
      {
        'Street' => {
          score: 0,
          status: :street,
        },
        'Shelter' => {
          score: 1,
          status: :shelter,
        },
        'Doubling Up' =>  {
          score: 2,
          status: :doubling_up,
        },
        'Transitional Housing / Residential Treatment Program' => {
          score: 3,
          status: :temporary,
        },
        'Motel' => {
          score: 3,
          status: :temporary,
        },
        'Assisted Living / Nursing Home / Rest Home' => {
          score: 4,
          status: :permanent,
        },
        'Supportive Housing' => {
          score: 4,
          status: :permanent,
        },
        'Housing with No Supports' => {
          score: 4,
          status: :permanent,
        },
        'Housing with no Support Services' => {
          score: 4,
          status: :permanent,
        },
        # 'Unknown',
        # 'Other',
      }.freeze
    end

    def self.health_housing_outcome(answer)
      health_housing_outcomes.keys.include?(answer)
    end

    def self.health_housing_score(answer)
       health_housing_outcomes[answer].try(:[], :score) || 0
    end

    def self.health_housing_temporary_outcomes
      health_housing_outcomes.select{|_,v| v[:status] == :temporary}.keys
    end

    def self.health_housing_permanent_outcomes
      health_housing_outcomes.select{|_,v| v[:status] == :permanent}.keys
    end

    def self.health_housing_positive_outcomes
      health_housing_outcomes.select{|_,v| v[:positive]}.keys
    end

    def self.health_housing_negative_outcomes
      health_housing_outcomes.select{|_,v| ! v[:positive]}.keys
    end


    def health_self_sufficiency_scores
      self_sufficiency_assessments.order(collected_at: :desc).limit(4).map do |assessment|
        # these should only have one section at this time
        scores = []
        if assessment.answers[:sections].count > 0
          scores = assessment.answers[:sections].first[:questions].select do |row|
            ssm_question_titles.include?(row[:question])
          end.map do |row|
            title = row[:question].gsub('SCORE', '').titleize
            value = row[:answer].to_f.round
            [title, value]
          end
        end
        {
          collected_at: assessment.collected_at,
          collection_location: assessment.collection_location,
          scores: scores,
        }
      end.compact
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


    def ssm_question_titles
      @ssm_question_titles ||= [
        "HOUSING SCORE",
        "INCOME/MONEY MANAGEMENT SCORE",
        "NON-CASH BENEFITS SCORE",
        "DISABILITIES SCORE",
        "FOOD SCORE",
        "EMPLOYMENT SCORE",
        "ADULT EDUCATION/TRAINING SCORE",
        "MOBILITY/TRANSPORTATION SCORE",
        "LIFE SKILLS & ADLs SCORE",
        "HEALTH CARE COVERAGE SCORE",
        "PHYSICAL HEALTH SCORE",
        "MENTAL HEALTH SCORE",
        "SUBSTANCE USE SCORE",
        "CRIMINAL JUSTICE SCORE",
        "LEGAL NON-CRIMINAL SCORE",
        "SAFETY SCORE",
        "RISK SCORE",
        "FAMILY & SOCIAL RELATIONSHIPS SCORE",
        "COMMUNITY INVOLVEMENT SCORE",
        "DAILY TIME MANAGEMENT SCORE",
        "PARENTING SKILLS SCORE",
        "Total"
      ]
    end
  end
end
