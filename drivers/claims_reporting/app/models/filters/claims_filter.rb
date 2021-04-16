###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# provides validation for date ranges
module Filters
  class ClaimsFilter < ::Filters::FilterBase
    attribute :food_insecurity, Integer, default: 0
    attribute :cohort_type, Symbol, default: :engaged_history # or :selected_period
    attribute :acos, Array, default: []

    def available_age_ranges
      super
    end

    def available_food_insecurities
      scores = Health::SelfSufficiencyMatrixForm::SECTIONS[:food]
      scores = scores.map { |score, text| [score, "#{text} (#{score})"] }.to_h
      scores[0] = 'All'
      scores.invert
    end

    def available_cohort_types
      {
        'Engaged History' => :engaged_history,
        'Selected Period' => :selected_period,
      }
    end

    def available_acos
      Health::AccountableCareOrganization.active.pluck(:short_name, :id)
    end

    def for_params
      super.deep_merge(
        {
          filters: {
            acos: acos,
            food_insecurity: food_insecurity,
            cohort_type: cohort_type,
          },
        },
      )
    end

    def chosen_acos
      Health::AccountableCareOrganization.active.where(id: acos)
    end

    def chosen_food_insecurity
      available_food_insecurities.invert[food_insecurity]
    end

    def chosen_cohort_type
      available_cohort_types.invert[cohort_type]
    end

    def describe(key, value = chosen(key))
      title = case key
      when :acos
        'ACOs'
      when :food_insecurity
        'Food Insecurity'
      when :cohort_type
        'Cohort Type'
      end

      return unless value.present?
      return super(key, value) if title.blank?

      [title, value]
    end

    def chosen(key)
      v = case key

      when :acos
        chosen_acos
      when :food_insecurity
        chosen_food_insecurity
      when :cohort_type
        chosen_cohort_type
      end

      return super(key) if v.blank?

      v
    end
  end
end
