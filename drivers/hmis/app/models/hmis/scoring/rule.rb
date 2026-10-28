###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  module Scoring
    # Stores per-question scoring criteria (match type, config, and weight) used to evaluate assessment
    # responses as part of a larger scoring algorithm.
    #
    # Added to support HmisExternalApis::AcHmis::AltAhaCalculator, which loads rules for its
    # alt_aha_* algorithms and sums each rule's contribution against Housing Needs Assessment values.
    # A rule can pair a second criterion (secondary_*), in which case its weight applies to the product of both terms.
    # The model is intentionally generic and could be reused for other complex form-based scoring.
    # In general, prefer to use built-in scoring capabilities in the FormDefinition whenever possible.
    class Rule < ::GrdaWarehouseBase
      self.table_name = 'hmis_scoring_rules'

      RANGE = 'range'
      EXACT_MATCH = 'exact_match'
      VALUE = 'value'
      INCLUDE = 'include'
      DAYS_DIFF = 'days_diff'
      CRITERIA_TYPES = [RANGE, EXACT_MATCH, VALUE, INCLUDE, DAYS_DIFF].freeze

      # Transforms a VALUE or DAYS_DIFF criterion can apply to its number, named in criteria_config['transform'].
      # Named rather than stored as expressions so that no customer-supplied math is ever evaluated.
      TRANSFORMS = {
        'square' => ->(x) { x**2 },
        'cube' => ->(x) { x**3 },
        'quartic' => ->(x) { x**4 },
        'log1p' => ->(x) { Math.log(1 + [x, 0].max) },
      }.freeze

      validates :model_version, presence: true
      validates :criteria_type, inclusion: { in: CRITERIA_TYPES }
      validates :secondary_criteria_type, inclusion: { in: CRITERIA_TYPES }, allow_nil: true
      validate :valid_criteria_config
      validate :valid_secondary_criteria

      scope :for_algorithm, ->(algorithm) { where(algorithm: algorithm) }
      scope :for_form, ->(form_definition_identifier) { where(form_definition_identifier: form_definition_identifier) }

      # Evaluate this rule against a response value and return the score contribution.
      # Paired and DAYS_DIFF rules need more than one input, so they must use evaluate_values.
      def evaluate(response_value)
        raise "Scoring rule #{id} needs more than one input; use evaluate_values" if secondary_link_id.present? || criteria_type == DAYS_DIFF

        criterion_term(criteria_type, criteria_config, response_value, nil) * weight
      end

      # Evaluate this rule against the assessment's values and return the score contribution:
      # weight × primary term × secondary term, where the secondary term is 1 when there is no second criterion.
      # DAYS_DIFF criteria count days elapsed up to assessment_date, so it is required for them.
      def evaluate_values(values_by_link_id, assessment_date: nil)
        primary = criterion_term(criteria_type, criteria_config, values_by_link_id[link_id], assessment_date)
        secondary = if secondary_link_id.present?
          criterion_term(secondary_criteria_type, secondary_criteria_config || {}, values_by_link_id[secondary_link_id], assessment_date)
        else
          1
        end

        primary * secondary * weight
      end

      private

      # Returns 1 or 0 for a match criterion, or the (optionally transformed) number for VALUE and DAYS_DIFF
      def criterion_term(type, config, value, assessment_date)
        case type
        when RANGE then range_match?(config, value) ? 1 : 0
        when EXACT_MATCH then exact_match?(config, value) ? 1 : 0
        when INCLUDE then include?(config, value) ? 1 : 0
        when VALUE then apply_transform(config, convert_to_numeric(value) || 0)
        when DAYS_DIFF then days_diff_term(config, value, assessment_date)
        else raise "Unknown criteria type #{type} in scoring rule #{id}" # should not happen due to validations
        end
      end

      # Days elapsed between a date answer and the assessment date: the scorecards' `CURRENT_DATE - x`,
      # used for terms like "when did your current homeless episode begin?"
      # An unanswered date contributes 0, both as a number and as a match.
      def days_diff_term(config, value, assessment_date)
        # A missing date is a caller bug, not a missing answer, so fail rather than score 0
        raise "Scoring rule #{id} counts days elapsed and requires an assessment date" if assessment_date.nil?

        date = convert_to_date(value)
        return 0 if date.nil?

        # Counted to the assessment date rather than today, so recalculating later gives the same score
        days = (assessment_date.to_date - date).to_i
        # Some terms ask whether the count is exactly 0 or 1 days (began that day or the day before)
        return exact_match?(config, days) ? 1 : 0 if config.key?('match_value')

        apply_transform(config, days)
      end

      def apply_transform(config, number)
        transform = config['transform']
        transform ? TRANSFORMS.fetch(transform).call(number) : number
      end

      def range_match?(config, value)
        numeric_value = convert_to_numeric(value)
        return false if numeric_value.nil?

        # gather up all the range-related criteria in a list and check if they all match.
        config.all? do |operator, threshold|
          case operator
          when 'gt' then numeric_value > threshold
          when 'gte' then numeric_value >= threshold
          when 'lt' then numeric_value < threshold
          when 'lte' then numeric_value <= threshold
          else raise "Unknown operator #{operator} in scoring rule #{id}" # should not happen due to validations
          end
        end
      end

      def exact_match?(config, value)
        match_value = config['match_value']

        # Handle nil matching explicitly
        return value.nil? if match_value.nil?

        # For non-nil values, convert both to strings for comparison
        value.to_s == match_value.to_s
      end

      def include?(config, value)
        include_value = config['include']
        return false if include_value.nil? || value.nil?

        # Check if the response array includes the target value (convert both to strings for comparison)
        Array.wrap(value).map(&:to_s).include?(include_value.to_s)
      end

      def convert_to_numeric(value)
        case value
        when Numeric
          value
        when String
          begin
            # Try integer first, then float
            value.match?(/\A-?\d+\z/) ? Integer(value) : Float(value)
          rescue ArgumentError
            nil
          end
        end
      end

      # Form values carry dates as ISO 8601 strings
      def convert_to_date(value)
        case value
        when Date then value
        when String then Date.iso8601(value) if value.present?
        end
      end

      def valid_criteria_config
        validate_config(:criteria_config, criteria_type, criteria_config)
      end

      def valid_secondary_criteria
        if secondary_link_id.blank?
          errors.add(:secondary_link_id, 'is required when a secondary criterion is given') if secondary_criteria_type.present? || secondary_criteria_config.present?
        elsif secondary_criteria_type.blank?
          errors.add(:secondary_criteria_type, 'is required when a secondary link_id is given')
        else
          validate_config(:secondary_criteria_config, secondary_criteria_type, secondary_criteria_config || {})
        end
      end

      def validate_config(attribute, type, config)
        case type
        when RANGE then validate_range_config(attribute, config)
        when EXACT_MATCH then validate_exact_match_config(attribute, config)
        when INCLUDE then validate_include_config(attribute, config)
        when VALUE then validate_transform_config(attribute, config)
        when DAYS_DIFF then validate_days_diff_config(attribute, config)
        end
      end

      def validate_range_config(attribute, config)
        valid_operators = ['gt', 'gte', 'lt', 'lte']
        config_operators = config.keys & valid_operators

        errors.add(attribute, 'Range criteria must specify at least one of: gt, gte, lt, lte') if config_operators.empty?
        errors.add(attribute, 'Cannot specify both gt and gte') if config.key?('gt') && config.key?('gte')
        errors.add(attribute, 'Cannot specify both lt and lte') if config.key?('lt') && config.key?('lte')

        # Check bounds make sense
        lower = config['gt'] || config['gte']
        upper = config['lt'] || config['lte']
        errors.add(attribute, 'Lower bound must be less than upper bound') if lower && upper && lower >= upper
      end

      def validate_exact_match_config(attribute, config)
        # `match_value` key has to exist, but value can be nil
        errors.add(attribute, 'Exact match criteria must specify a match_value') unless config.key?('match_value')
      end

      def validate_include_config(attribute, config)
        errors.add(attribute, 'Include criteria must specify an include value') unless config.key?('include')
      end

      def validate_transform_config(attribute, config)
        return unless config.key?('transform')

        errors.add(attribute, "Transform must be one of: #{TRANSFORMS.keys.join(', ')}") unless TRANSFORMS.key?(config['transform'])
      end

      # Days elapsed are either matched exactly (e.g. 0 for "began today") or used as a number, optionally transformed
      def validate_days_diff_config(attribute, config)
        if config.key?('match_value')
          errors.add(attribute, 'Days diff criteria cannot specify both a match_value and a transform') if config.key?('transform')
          errors.add(attribute, 'Days diff match_value must be a whole number of days') unless config['match_value'].is_a?(Integer)
        else
          validate_transform_config(attribute, config)
        end
      end
    end
  end
end
