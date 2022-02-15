###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthCharts
  extend ActiveSupport::Concern
  included do
    def health_housing_stati
      stati = case_management_notes.map do |form|
        answer = form.housing_status
        next unless answer.present?

        answer = self.class.clean_health_housing_outcome_answer(answer)
        score = self.class.health_housing_score(answer)
        next unless score

        next unless self.class.health_housing_outcome(answer)

        {
          date: form.collected_at.to_date,
          score: score,
          status: answer,
          source: 'ETO',
          patient_id: patient.id,
        }
      end.compact
      if patient.housing_status_timestamp.present?
        score = self.class.health_housing_score(patient.housing_status)
        if score
          stati << {
            date: patient.housing_status_timestamp.to_date,
            score: score,
            status: patient.housing_status,
            source: 'EPIC',
            patient_id: patient.id,
          }
        end
      end
      if patient.sdh_case_management_notes.any?
        stati += patient.sdh_case_management_notes.
          select do |note|
            note.housing_status.present? && note.date_of_contact.present?
          end.map do |note|
            score = self.class.health_housing_score(note.housing_status)
            next unless score

            {
              date: note.date_of_contact.to_date,
              score: score,
              status: note.housing_status,
              source: 'Care Hub',
              patient_id: patient.id,
            }
          end.compact
      end
      if patient.epic_case_notes.any?
        stati += patient.epic_case_notes.
          select do |note|
            note.homeless_status.present? && note.contact_date.present?
          end.map do |note|
            score = self.class.health_housing_score(note.homeless_status)
            next unless score

            {
              date: note.contact_date.to_date,
              score: score,
              status: note.homeless_status,
              source: 'EPIC',
              patient_id: patient.id,
            }
          end.compact
      end
      stati.sort_by { |m| m[:date] }
    end

    def self.health_housing_bucket(answer)
      case answer
      when *health_housing_temporary_outcomes
        'Temporary Housing'
      when *health_housing_permanent_outcomes
        'Permanent Housing'
      when *health_housing_negative_outcomes
        answer
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
        'Doubling Up' => {
          score: 2,
          status: :doubling_up,
        },
        'Doubled Up' => {
          score: 2,
          status: :doubling_up,
        },
        'Transitional Housing / Residential Treatment Program' => {
          score: 3,
          status: :temporary,
        },
        'Transitional Housing or Residential Treatment Program' => {
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
        'Assisted Living Facility, Nursing Home, Rest Home' => {
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
        'Housing with no Supportive Services' => {
          score: 4,
          status: :permanent,
        },
        # 'Unknown',
        # 'Other',
      }.freeze
    end

    def self.clean_health_housing_outcome_answer(answer)
      # February 2018, the wording of two of the options for our housing status question was changed by OCHIN
      # "Doubling up" was changed to "Doubled up"
      # "Housing with no support services" was changed to "Housing with no supportive services"
      changes = {
        'Doubled up' => 'Doubling up',
        'Housing with no supportive services' => 'Housing with no support services',
      }
      if changes.key?(answer)
        changes[answer]
      else
        answer
      end
    end

    def self.health_housing_outcome(answer)
      health_housing_outcomes.key?(answer)
    end

    def self.health_housing_score(answer)
      health_housing_outcomes[answer].try(:[], :score)
    end

    def self.health_housing_outcome_status(answer)
      health_housing_outcomes[answer].try(:[], :status) || :unknown
    end

    def self.health_housing_temporary_outcomes
      health_housing_outcomes.select { |_, v| v[:status] == :temporary }.keys
    end

    def self.health_housing_permanent_outcomes
      health_housing_outcomes.select { |_, v| v[:status] == :permanent }.keys
    end

    def self.health_housing_positive_outcomes
      health_housing_outcomes.select { |_, v| v[:positive] }.keys
    end

    def self.health_housing_negative_outcomes
      health_housing_outcomes.reject { |_, v| v[:positive] }.keys
    end

    def load_health_self_sufficiency_objects
      old_objects = self_sufficiency_assessments.collected.order(collected_at: :desc).limit(4)
      new_objects = patient.self_sufficiency_matrix_forms.completed.order(completed_at: :desc).limit(4)
      (old_objects + new_objects).sort_by do |o|
        if o.is_a?(GrdaWarehouse::HmisForm)
          o.collected_at
        elsif o.is_a?(Health::SelfSufficiencyMatrixForm)
          o.completed_at
        end
      end.reverse.first(4)
    end

    def load_health_self_sufficiency_old_object_scores(assessment)
      # client.self_sufficiency_assessments
      scores = []
      if assessment.answers[:sections].count.positive?
        scores = assessment.answers[:sections].first[:questions].select do |row|
          ssm_question_titles.include?(row[:question])
        end.map do |row|
          title = row[:question].gsub('SCORE', '').titleize
          value = row[:answer].to_f.round
          [title, value]
        end
        total = scores.select { |m| m.first == 'Total' }.first.last
        scores.delete_if { |m| m.first == 'Total' }
      end
      {
        collected_at: assessment.collected_at,
        collection_location: assessment.collection_location,
        scores: scores.reverse,
        total: total,
      }
    end

    def load_health_self_sufficiency_new_object_scores(assessment)
      # patient.self_sufficiency_matrix_forms
      scores = assessment.attributes.select do |k, _v|
        k.split('_').last == 'score'
      end.map do |k, v|
        [assessment.ssm_question_title(k), v]
      end
      # new self_sufficiency_matrix_forms don't have this item
      scores.push(['Parenting Skills ', 0])
      {
        collected_at: assessment.completed_at,
        collection_location: assessment.collection_location || '',
        scores: scores.reverse,
        total: assessment.total_score,
      }
    end

    def health_self_sufficiency_scores
      load_health_self_sufficiency_objects.map do |object|
        if object.is_a?(GrdaWarehouse::HmisForm)
          load_health_self_sufficiency_old_object_scores(object)
        elsif object.is_a?(Health::SelfSufficiencyMatrixForm)
          load_health_self_sufficiency_new_object_scores(object)
        end
      end.compact
      # self_sufficiency_assessments.order(collected_at: :desc).limit(4).map do |assessment|
      #   # these should only have one section at this time
      #   scores = []
      #   if assessment.answers[:sections].count > 0
      #     scores = assessment.answers[:sections].first[:questions].select do |row|
      #       ssm_question_titles.include?(row[:question])
      #     end.map do |row|
      #       title = row[:question].gsub('SCORE', '').titleize
      #       value = row[:answer].to_f.round
      #       [title, value]
      #     end
      #     total = scores.select{|m| m.first == 'Total'}.first.last
      #     scores.delete_if{|m|  m.first == 'Total'}
      #   end
      #   {
      #     collected_at: assessment.collected_at,
      #     collection_location: assessment.collection_location,
      #     scores: scores.reverse,
      #     total: total,
      #   }
      # end.compact
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
        'HOUSING SCORE',
        'INCOME/MONEY MANAGEMENT SCORE',
        'NON-CASH BENEFITS SCORE',
        'DISABILITIES SCORE',
        'FOOD SCORE',
        'EMPLOYMENT SCORE',
        'ADULT EDUCATION/TRAINING SCORE',
        'MOBILITY/TRANSPORTATION SCORE',
        'LIFE SKILLS & ADLs SCORE',
        'HEALTH CARE COVERAGE SCORE',
        'PHYSICAL HEALTH SCORE',
        'MENTAL HEALTH SCORE',
        'SUBSTANCE USE SCORE',
        'CRIMINAL JUSTICE SCORE',
        'LEGAL NON-CRIMINAL SCORE',
        'SAFETY SCORE',
        'RISK SCORE',
        'FAMILY & SOCIAL RELATIONSHIPS SCORE',
        'COMMUNITY INVOLVEMENT SCORE',
        'DAILY TIME MANAGEMENT SCORE',
        'PARENTING SKILLS SCORE',
        'Total',
      ]
    end
  end
end
