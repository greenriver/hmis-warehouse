###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis
  class AltAhaCalculator
    ALT_AHA_NAMESPACE = 'alt_aha'

    # owner can be: an enrollment (when AHA score is calculated on an unsaved assessment), or an assessment (when the assessment is being saved)
    def initialize(values_by_link_id:, client:, user: nil, owner: nil, form_definition_identifier:)
      @values_by_link_id = values_by_link_id.merge(
        # inject values from client
        'client_demographics_age' => client.age,
        'client_demographics_gender' => client.gender_fields,
      )
      @user = user
      @owner = owner
      @form_definition_identifier = form_definition_identifier

      # Cache all Alt-AHA scoring rules
      @all_rules = Hmis::Scoring::Rule.
        for_form(@form_definition_identifier).
        where(algorithm: ['alt_aha_1', 'alt_aha_2', 'alt_aha_3'])
    end

    def calculate_score
      components = calculate_components(@values_by_link_id)
      total_points = components.values.sum { |result| result[:points] + result[:intercept] }
      alt_aha_score = convert_total_points_to_score(total_points)

      calculation_log = Hmis::Scoring::CalculationLog.create!(
        namespace: ALT_AHA_NAMESPACE,
        final_score: alt_aha_score,
        calculation_details: { **components, total_points: total_points },
        owner: @owner,
        user: @user,
      )

      [alt_aha_score, calculation_log]
    end

    def required_link_ids
      # Group rules by link_id
      rules_by_link_id = @all_rules.group_by(&:link_id)

      # Return a list of required link IDs that correspond to scoring rules
      rules_by_link_id.filter_map do |link_id, rules|
        # Skip link_ids that only have rules matching a missing value (exact_match rules with match_value: null)
        only_missing_rules = rules.all? do |rule|
          rule.criteria_type == Hmis::Scoring::Rule::EXACT_MATCH &&
          rule.criteria_config['match_value'].nil?
        end

        link_id unless only_missing_rules
      end
    end

    private

    def calculate_components(values_by_link_id)
      {
        alt_aha_1: calculate_algo_1_score(values_by_link_id),
        alt_aha_2: calculate_algo_2_score(values_by_link_id),
        alt_aha_3: calculate_algo_3_score(values_by_link_id),
      }
    end

    def calculate_algorithm_score(algorithm, values_by_link_id)
      # Filter cached rules for the specific algorithm, then group by link_id
      algorithm_rules = @all_rules.select { |rule| rule.algorithm == algorithm }
      rules_by_link_id = algorithm_rules.group_by(&:link_id)
      raise "No rules found for #{algorithm} #{@form_definition_identifier}" if rules_by_link_id.empty?

      # Evaluate all rules, treating missing values as nil
      rules_by_link_id.sum do |link_id, rules|
        response_value = values_by_link_id[link_id]
        rules.sum { |rule| rule.evaluate(response_value) }
      end
    end

    def calculate_probability(score)
      1.0 / (1.0 + Math.exp(-score))
    end

    def calculate_algo_1_score(values_by_link_id)
      raw_score = calculate_algorithm_score('alt_aha_1', values_by_link_id)
      probability = calculate_probability(raw_score)

      if probability > 0.770969964
        points = 5
      elsif probability > 0.659553104
        points = 4
      elsif probability > 0.554763958
        points = 3
      elsif probability > 0.411783946
        points = 2
      elsif probability > 0.290397211
        points = 1
      else
        points = 0
      end

      {
        raw_score: raw_score,
        probability: probability,
        points: points,
        intercept: -0.412537657,
      }
    end

    def calculate_algo_2_score(values_by_link_id)
      raw_score = calculate_algorithm_score('alt_aha_2', values_by_link_id)
      probability = calculate_probability(raw_score)

      if probability > 0.790901794
        points = 5
      elsif probability > 0.710324173
        points = 4
      elsif probability > 0.572049905
        points = 3
      elsif probability > 0.404112904
        points = 2
      elsif probability > 0.19008731
        points = 1
      else
        points = 0
      end

      {
        raw_score: raw_score,
        probability: probability,
        points: points,
        intercept: -0.6995659699,
      }
    end

    def calculate_algo_3_score(values_by_link_id)
      raw_score = calculate_algorithm_score('alt_aha_3', values_by_link_id)
      probability = calculate_probability(raw_score)

      if probability > 0.833850594
        points = 5
      elsif probability > 0.730025792
        points = 4
      elsif probability > 0.603898063
        points = 3
      elsif probability > 0.428651806
        points = 2
      elsif probability > 0.220069799
        points = 1
      else
        points = 0
      end

      {
        raw_score: raw_score,
        probability: probability,
        points: points,
        intercept: 1.065580188,
      }
    end

    def convert_total_points_to_score(total_points)
      case total_points
      when 11...16 then 10
      when 9...11  then 9
      when 8...9   then 8
      when 7...8   then 7
      when 6...7   then 6
      when 5...6   then 5
      when 4...5   then 4
      when 3...4   then 3
      when 1...3   then 2
      when 0...1   then 1
      else 0
      end
    end
  end
end
