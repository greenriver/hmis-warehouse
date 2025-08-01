###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis
  class AltAhaCalculator
    ALT_AHA_ALGO_NAMESPACE = 'alt_aha'

    def calculate_score(_assessment_id, values_by_link_id)
      return 0 if values_by_link_id.blank?

      algorithms = AcHmis::Scoring::Algorithm.where(namespace: ALT_AHA_ALGO_NAMESPACE)
      return 0 if algorithms.empty?

      score_details = algorithms.map do |algorithm|
        calculate_algorithm_score(algorithm, values_by_link_id)
      end

      total_points = score_details.map { |details| details[:points] }.sum
      alt_aha_score = convert_total_points_to_score(total_points)

      log_calculation(values_by_link_id, score_details, total_points, alt_aha_score)

      alt_aha_score
    end

    def calculate_algorithm_score(algorithm, values_by_link_id)
      # Get all scoring rules for this algorithm, grouped by link_id
      rules_by_link_id = AcHmis::Scoring::Rule.rules_by_link_id(algorithm)

      # Calculate weighted score
      weighted_score = 0
      values_by_link_id.each do |link_id, response_value|
        rules = rules_by_link_id[link_id.to_s] || []
        matching_rules = rules.select { |rule| rule.matches_value?(response_value) }

        # Sum weights from all matching rules for this link_id
        weighted_score += matching_rules.sum(&:weight)
      end

      logistic_score = 1.0 / (1.0 + Math.exp(-weighted_score))
      points = convert_logistic_score_to_points(logistic_score, algorithm)

      {
        algorithm_name: algorithm.name,
        weighted_score: weighted_score,
        logistic_score: logistic_score,
        points: points,
      }
    end

    private

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

    def convert_logistic_score_to_points(logistic_score, algorithm)
      thresholds = AcHmis::Scoring::Threshold.thresholds_for_algorithm(algorithm)

      # Find the first threshold that the probability exceeds
      thresholds.each do |threshold, points|
        return points if logistic_score > threshold
      end

      # If probability doesn't exceed any threshold, return 0 points
      0
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
