###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class EngagementFilter < ::Filters::FilterBase
    attribute :food_insecurity, Integer
    attribute :cohort_type, Symbol, default: :engaged_history # or :selected_period
    attribute :acos, Array, default: []

    def available_age_ranges
      super
    end

    def available_food_insecurities
      scores = Health::SelfSufficiencyMatrixForm::SECTIONS[:food]
      scores = scores.map { |score, text| [score, "#{score} - #{text}"] }.to_h
      scores.invert
    end

    # engaged_history - patients engaged for the date range
    # selected_period - patients with a minimum engagement length of the start of the range
    def available_cohort_types
      {
        'Patients engaged for time period' => :engaged_history,
        'Longitudinal, claims occuring within time period' => :selected_period,
      }
    end

    def available_acos
      Health::AccountableCareOrganization.active.pluck(:short_name, :id).sort
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
      ).tap do |info|
        info[:filters].delete(:start)
        info[:filters].delete(:end)
      end
    end

    def chosen_acos
      Health::AccountableCareOrganization.active.where(id: acos).pluck(:short_name).sort
    end

    def chosen_food_insecurity
      available_food_insecurities.invert[food_insecurity]
    end

    def chosen_cohort_type
      available_cohort_types.invert[cohort_type]
    end

    def set_from_params(params) # rubocop:disable Naming/AccessorMethodName
      super.tap do |_x|
        self.acos = Array(params[:acos]).reject(&:blank?)
        self.food_insecurity = params[:food_insecurity]
        self.cohort_type = params[:cohort_type]
      end
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
