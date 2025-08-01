###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis
  class AltAhaCalculator
    ALT_AHA_NAMESPACE = 'alt_aha'

    def calculate_score(_enrollment_id, values_by_link_id)
      return 0 if values_by_link_id.blank?

      alt_aha_1_result = calculate_algo_1_score(values_by_link_id)
      alt_aha_2_result = calculate_algo_2_score(values_by_link_id)
      alt_aha_3_result = calculate_algo_3_score(values_by_link_id)

      total_points = [alt_aha_1_result[:points], alt_aha_2_result[:points], alt_aha_3_result[:points]].sum
      alt_aha_score = convert_total_points_to_score(total_points)

      # log_calculation(values_by_link_id, score_details, total_points, alt_aha_score)

      alt_aha_score
    end

    private

    def calculate_algorithm_score(algorithm, values_by_link_id)
      # Get all scoring rules for this algorithm, grouped by link_id
      rules_by_link_id = AcHmis::Scoring::Rule.rules_by_link_id(algorithm)

      score = 0
      values_by_link_id.each do |link_id, response_value|
        rules = rules_by_link_id[link_id.to_s] || []
        matching_rules = rules.select { |rule| rule.matches_value?(response_value) }

        # Sum weights from all matching rules for this link_id
        score += matching_rules.sum(&:weight)
      end

      score
    end

    def calculate_probability(score)
      1.0 / (1.0 + Math.exp(-score))
    end

    def calculate_algo_1_score(values_by_link_id)
      score = calculate_algorithm_score('alt_aha_1', values_by_link_id)
      probability = calculate_probability(score)

      # todo @martha - can this be consolidated to reduce repeated code? (but if so, is it any more readable?)
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
        algorithm: 'alt_aha_1',
        score: score,
        probability: probability,
        points: points,
      }
    end

    def calculate_algo_2_score(values_by_link_id)
      score = calculate_algorithm_score('alt_aha_2', values_by_link_id)
      probability = calculate_probability(score)

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
        algorithm: 'alt_aha_2',
        score: score,
        probability: probability,
        points: points,
      }
    end

    def calculate_algo_3_score(values_by_link_id)
      score = calculate_algorithm_score('alt_aha_2', values_by_link_id)
      probability = calculate_probability(score)

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
        algorithm: 'alt_aha_3',
        score: score,
        probability: probability,
        points: points,
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

    # todo @martha - properly log, including assessment ID or enrollment ID?
    # maybe logging happens when the form is submitted (aka not now)
    def log_calculation(values_by_link_id, score_details, total_points, final_score)
      AcHmis::Scoring::CalculationLog.create!(
        namespace: ALT_AHA_ALGO_NAMESPACE,
        final_score: final_score,
        calculation_details: {
          score_details: score_details,
          total_points: total_points,
        },
        input_values: values_by_link_id,
      )
    end
  end
end
