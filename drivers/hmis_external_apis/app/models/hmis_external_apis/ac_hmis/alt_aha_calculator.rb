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
    end

    def calculate_score
      components = calculate_components(@values_by_link_id)
      total_points = components.values.sum { |result| result[:points] + result[:intercept] }
      alt_aha_score = convert_total_points_to_score(total_points)

      calculation_log = AcHmis::Scoring::CalculationLog.new(
        namespace: ALT_AHA_NAMESPACE,
        final_score: alt_aha_score,
        calculation_details: { **components, total_points: total_points },
        owner: @owner,
        user: @user,
      )

      [alt_aha_score, calculation_log]
    end

    def calculate_score!
      alt_aha_score, calculation_log = calculate_score
      calculation_log.save!
      alt_aha_score
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
      rules_by_link_id = AcHmis::Scoring::Rule.
        for_form(@form_definition_identifier).
        for_algorithm(algorithm).
        group_by(&:link_id)
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
      return 10 if total_points >= 11 && total_points < 16
      return 9 if total_points >= 9 && total_points < 11
      return 8 if total_points >= 8 && total_points < 9
      return 7 if total_points >= 7 && total_points < 8
      return 6 if total_points >= 6 && total_points < 7
      return 5 if total_points >= 5 && total_points < 6
      return 4 if total_points >= 4 && total_points < 5
      return 3 if total_points >= 3 && total_points < 4
      return 2 if total_points >= 1 && total_points < 3
      return 1 if total_points >= 0 && total_points < 1

      0
    end
  end
end
