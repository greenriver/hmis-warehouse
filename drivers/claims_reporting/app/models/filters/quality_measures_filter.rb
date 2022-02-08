###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class QualityMeasuresFilter < ::Filters::FilterBase
    attribute :acos, Array, default: []

    # Ugh... default filters we aren't supporting,
    # need nil defaults so they dont show up in describe
    # or as_json
    attribute :sub_population, Symbol, default: nil
    attribute :limit_to_vispdat, Symbol, default: nil
    attribute :project_type_codes, Array, default: []
    attribute :household_type, Symbol, default: nil
    attribute :on, String, default: nil
    attribute :start, String, default: nil
    attribute :end, String, default: nil
    attribute :enforce_one_year_range, String, default: nil
    attribute :comparison_pattern, String, default: nil
    attribute :default_on, String, default: nil
    attribute :default_start, String, default: nil
    attribute :default_end, String, default: nil
    attribute :start_age, String, default: nil
    attribute :end_age, String, default: nil
    attribute :comparison_range_words, String, default: nil

    def for_params
      {
        filters: {
          acos: acos,
          races: races,
          genders: genders,
          ethnicities: ethnicities,
          age_ranges: age_ranges,
        },
      }
    end

    def set_from_params(params) # rubocop:disable Naming/AccessorMethodName
      super.tap do |_x|
        self.acos = Array(params[:acos]).reject(&:blank?)
      end
    end

    def serializable_hash
      attributes.reject { |_k, v| v.blank? }
    end

    def available_acos
      Health::AccountableCareOrganization.active.pluck(:short_name, :id).sort
    end

    def chosen_acos
      Health::AccountableCareOrganization.where(id: acos).pluck(:short_name).sort
    end

    def describe(key, value = chosen(key))
      return unless value.present?

      if key == :acos
        ['ACOs', value]
      else
        super
      end
    end

    def chosen(key)
      if key == :acos
        chosen_acos
      else
        super
      end
    end
  end
end
