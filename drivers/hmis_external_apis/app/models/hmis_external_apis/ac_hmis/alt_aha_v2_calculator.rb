###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis
  # Calculates the Alt-AHA score with version 2 of Allegheny's model. Used instead of AltAhaCalculator
  # when HmisExternalApis::AcHmis::Configuration#alt_aha_model_version is 2; build it through AltAhaCalculatorFactory.
  #
  # How scoring works:
  # Four component algorithms (alt_aha_1 through alt_aha_4) each convert weighted assessment responses into a
  # probability, then into 0–5 points by finding the first cutoff the probability is at or below.
  # Points combine as alt_aha_1 + alt_aha_2 + alt_aha_3 + 3 × alt_aha_4 (0–30), which maps to a final 1–10 score.
  #
  # Per-question weights and match criteria are stored as Hmis::Scoring::Rule records with model_version 2.
  # Unlike version 1, rules can pair two questions and count days elapsed up to the assessment date.
  class AltAhaV2Calculator
    # Raised when the assessment date is blank, which the user can fix by filling it in
    class MissingAssessmentDateError < StandardError; end

    MODEL_VERSION = 2
    ALT_AHA_NAMESPACE = 'alt_aha'
    CLIENT_AGE_LINK_ID = 'client_demographics_age'
    CLIENT_GENDER_LINK_ID = 'client_demographics_gender'

    # Intercepts must match the __INTERCEPT__ rows in Allegheny's scorecards; the scorecard import checks them.
    ALGORITHMS = {
      'alt_aha_1' => {
        intercept: -1.4572595885139406,
        cutoffs: [0.10136829954772385, 0.18188473977043185, 0.24231086499674537, 0.4431775897553492, 0.6457370050358396],
      },
      # The repeated cutoff is as given, so 3 points is unreachable.
      'alt_aha_2' => {
        intercept: -2.896030222530059,
        cutoffs: [0.04431929244957452, 0.09659627513183767, 0.14573992561474022, 0.14573992561474022, 0.3438205847838196],
      },
      'alt_aha_3' => {
        intercept: -1.2470872543522769,
        cutoffs: [0.028333677671095934, 0.06089627861378619, 0.16208791699443476, 0.3867726619202931, 0.6289718199104053],
      },
      'alt_aha_4' => {
        intercept: -2.5415033196254435,
        cutoffs: [0.2657769425601322, 0.40294116099436367, 0.6300888752727332, 0.7839260035476774, 0.9367820757404531],
      },
    }.freeze

    # Total points at or below each cutoff map to scores 1 through 9; anything above the last is 10
    SCORE_CUTOFFS = [1, 5, 8, 9, 10, 12, 16, 19, 24].freeze

    # owner can be: an enrollment (when AHA score is calculated on an unsaved assessment), or an assessment (when the assessment is being saved)
    def initialize(values_by_link_id:, client:, definition:, user: nil, owner: nil)
      @values_by_link_id = values_by_link_id.merge(
        # inject values from client
        CLIENT_AGE_LINK_ID => client.age,
        CLIENT_GENDER_LINK_ID => determine_gender(client),
      )
      # The form being scored: its identifier selects the rules, and its assessment date item says
      # which submitted value holds the date that days_diff rules count from
      @definition = definition
      @user = user
      @owner = owner

      @all_rules = Hmis::Scoring::Rule.
        for_form(definition.identifier).
        where(model_version: MODEL_VERSION, algorithm: ALGORITHMS.keys).
        to_a
    end

    def calculate_score
      assessment_date = find_assessment_date
      components = ALGORITHMS.to_h do |algorithm, config|
        [algorithm.to_sym, calculate_algorithm(algorithm, config, assessment_date)]
      end
      total_points = components[:alt_aha_1][:points] +
        components[:alt_aha_2][:points] +
        components[:alt_aha_3][:points] +
        3 * components[:alt_aha_4][:points]
      alt_aha_score = convert_total_points_to_score(total_points)

      calculation_log = Hmis::Scoring::CalculationLog.create!(
        namespace: ALT_AHA_NAMESPACE,
        final_score: alt_aha_score,
        calculation_details: { **components, total_points: total_points, model_version: MODEL_VERSION },
        owner: @owner,
        user: @user,
      )

      [alt_aha_score, calculation_log]
    end

    # Every question a rule reads, including the second question of a paired rule
    def required_link_ids
      link_ids = @all_rules.flat_map { |rule| [rule.link_id, rule.secondary_link_id] }.compact.uniq
      link_ids - [CLIENT_AGE_LINK_ID, CLIENT_GENDER_LINK_ID]
    end

    private

    # Merged gender value accommodates both FY24 and FY26 values
    def determine_gender(client)
      if client.sex == 0 || client.woman == 1
        0
      elsif client.sex == 1 && client.man == 1
        1
      end
    end

    # days_diff rules count days elapsed up to the assessment date, so recalculating later gives the same score
    def find_assessment_date
      item = @definition.assessment_date_item
      raise "Form #{@definition.identifier} has no assessment date item" unless item

      date_string = @values_by_link_id[item.link_id]
      date = HmisUtil::Dates.safe_parse_date(date_string: date_string) if date_string.present?
      raise MissingAssessmentDateError, 'Alt-AHA score requires an assessment date' unless date

      date
    end

    def calculate_algorithm(algorithm, config, assessment_date)
      rules = @all_rules.select { |rule| rule.algorithm == algorithm }
      raise "No rules found for #{algorithm} #{@definition.identifier} model version #{MODEL_VERSION}" if rules.empty?

      raw_score = rules.sum { |rule| rule.evaluate_values(@values_by_link_id, assessment_date: assessment_date) }
      score = raw_score + config[:intercept]
      probability = 1.0 / (1.0 + Math.exp(-score))
      points = config[:cutoffs].index { |cutoff| probability <= cutoff } || config[:cutoffs].size

      {
        raw_score: raw_score,
        score: score,
        probability: probability,
        points: points,
      }
    end

    def convert_total_points_to_score(total_points)
      (SCORE_CUTOFFS.index { |cutoff| total_points <= cutoff } || SCORE_CUTOFFS.size) + 1
    end
  end
end
