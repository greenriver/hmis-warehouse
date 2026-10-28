###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  module Scoring
    # Checks that a set of scoring rules fits a form definition: every question a rule reads is on the form,
    # and every answer a rule matches is one the question can store. A rule that fails either check never
    # raises at scoring time; it just contributes 0, so this is the only place the mismatch shows up.
    #
    # Read-only, so it can run against a draft, published, or retired definition as often as needed.
    # Reports every problem rather than stopping at the first, since the output is the list of form fixes.
    class RuleValidator
      Issue = Struct.new(:link_id, :message, :rule_ids, keyword_init: true)

      MATCH_CONFIG_KEYS = {
        Rule::EXACT_MATCH => 'match_value',
        Rule::INCLUDE => 'include',
      }.freeze

      # ignored_link_ids are values the caller supplies itself rather than reading from the form, such as client demographics
      def initialize(rules:, definition:, ignored_link_ids: [])
        @rules = rules.to_a
        @definition = definition
        @ignored_link_ids = ignored_link_ids
      end

      def valid?
        issues.empty?
      end

      def missing_link_ids
        criteria.map(&:first).uniq.reject { |link_id| items.key?(link_id) }
      end

      # Problems the form must fix: missing questions, and matched answers that are not options
      def issues
        @issues ||= missing_question_issues + answer_option_issues
      end

      # Questions whose answer options come from a pick list reference, which this does not resolve
      def unchecked
        @unchecked ||= begin
          referenced = matched_criteria.
            select { |link_id, _, _| items[link_id].pick_list_reference.present? }.
            map { |link_id, _, rule_id| [link_id, nil, rule_id] }
          group_rule_ids(referenced) do |link_id, _value|
            "#{link_id} uses pick list #{items[link_id].pick_list_reference}; its answer options were not checked"
          end
        end
      end

      private

      # [link_id, criteria_type, criteria_config, rule_id] for both criteria of every rule
      def criteria
        @criteria ||= @rules.flat_map do |rule|
          slots = [[rule.link_id, rule.criteria_type, rule.criteria_config]]
          slots << [rule.secondary_link_id, rule.secondary_criteria_type, rule.secondary_criteria_config] if rule.secondary_link_id.present?
          slots.map { |link_id, type, config| [link_id, type, config || {}, rule.id] }
        end.reject { |link_id, _, _, _| @ignored_link_ids.include?(link_id) }
      end

      # [link_id, matched value, rule_id] for each criterion that matches a specific answer to a question on the form.
      # A null match_value is skipped because it matches a blank answer, which every question allows.
      def matched_criteria
        @matched_criteria ||= criteria.filter_map do |link_id, type, config, rule_id|
          key = MATCH_CONFIG_KEYS[type]
          next unless key && items.key?(link_id) && !config[key].nil?

          [link_id, config[key], rule_id]
        end
      end

      def missing_question_issues
        missing = criteria.reject { |link_id, _, _, _| items.key?(link_id) }.map { |link_id, _, _, rule_id| [link_id, nil, rule_id] }
        group_rule_ids(missing) { |link_id, _value| "#{link_id} is not a question on the form" }
      end

      def answer_option_issues
        invalid = matched_criteria.select do |link_id, value, _|
          allowed = allowed_values(items[link_id])
          allowed && allowed.exclude?(value.to_s)
        end

        group_rule_ids(invalid) do |link_id, value|
          "#{link_id} has no answer #{value.to_s.inspect}; it stores #{allowed_values(items[link_id]).map(&:inspect).join(', ')}"
        end
      end

      # The values a question with inline options can store: its options, plus any value an autofill writes,
      # such as a "0" written when a household has no minors. nil means the question has no fixed set to check.
      def allowed_values(item)
        return if item.pick_list_reference.present? || item.pick_list_options.blank?

        option_codes = item.pick_list_options.map { |option| option.code.to_s }
        autofill_codes = Array.wrap(item.autofill_values).flat_map { |autofill| [autofill.value_code, autofill.value_number] }.compact.map(&:to_s)
        (option_codes + autofill_codes).uniq
      end

      # One issue per [link_id, value], listing every rule that hit it
      def group_rule_ids(entries)
        entries.group_by { |link_id, value, _| [link_id, value.to_s] }.sort_by(&:first).map do |(link_id, _), grouped|
          Issue.new(link_id: link_id, message: yield(link_id, grouped.first[1]), rule_ids: grouped.map(&:last).uniq.sort)
        end
      end

      def items
        @definition.link_id_item_hash
      end
    end
  end
end
