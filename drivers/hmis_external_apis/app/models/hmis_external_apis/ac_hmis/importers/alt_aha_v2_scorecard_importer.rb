###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'csv'

# Loads Allegheny's version 2 Alt-AHA scorecards as Hmis::Scoring::Rule records for one form identifier.
#
# Each scorecard CSV holds one algorithm's terms, one per row, with up to two criteria slots (suffixed 1 and 2).
# The import replaces every model_version 2 rule for the identifier in one transaction, so a corrected scorecard
# is just a rerun. It checks only what the files can answer on their own; whether the rules fit a form is the
# rule validator's job.
#
# The algorithm_description column is never read: Allegheny considers the algorithm names sensitive.
class HmisExternalApis::AcHmis::Importers::AltAhaV2ScorecardImporter
  class InvalidScorecardError < StandardError; end

  CALCULATOR = HmisExternalApis::AcHmis::AltAhaV2Calculator
  RULE = Hmis::Scoring::Rule

  REQUIRED_HEADERS = [
    'algorithm',
    'question_id1', 'transform1', 'criteria_type1', 'criteria_config1',
    'question_id2', 'transform2', 'criteria_type2', 'criteria_config2',
    'weight'
  ].freeze

  # Intercepts arrive as rows, but the calculator keeps them as constants, so these rows are checked and skipped
  INTERCEPT_QUESTION_ID = '__INTERCEPT__'
  INTERCEPT_CRITERIA_TYPE = 'constant'

  # Scorecard criteria_config => [stored criteria_config, the transform label the row must carry]
  VALUE_CONFIGS = {
    {} => [{}, 'identity'],
    { 'transform' => 'x^2' } => [{ 'transform' => 'square' }, 'sq'],
    { 'transform' => 'x^3' } => [{ 'transform' => 'cube' }, 'cu'],
    { 'transform' => 'x^4' } => [{ 'transform' => 'quartic' }, 'quar'],
    { 'transform' => 'log1p(max(x,0))' } => [{ 'transform' => 'log1p' }, 'log'],
  }.freeze

  DAYS_DIFF_CONFIGS = {
    { 'days_diff' => 'CURRENT_DATE-x' } => [{}, 'identity'],
    { 'transform' => '(CURRENT_DATE-x)^2' } => [{ 'transform' => 'square' }, 'sq'],
    { 'transform' => '(CURRENT_DATE-x)^3' } => [{ 'transform' => 'cube' }, 'cu'],
    { 'transform' => '(CURRENT_DATE-x)^4' } => [{ 'transform' => 'quartic' }, 'quar'],
    { 'transform' => 'log1p(max(CURRENT_DATE-x, 0))' } => [{ 'transform' => 'log1p' }, 'log'],
    { 'match_value' => 0 } => [{ 'match_value' => 0 }, 'zero'],
    { 'match_value' => 1 } => [{ 'match_value' => 1 }, 'one'],
  }.freeze

  # Scorecard answer values that differ from what the calculator compares against. Every value of a listed
  # question must be mapped, so a scorecard that changes its labels fails instead of silently never matching.
  ANSWER_VALUES = {
    # The calculator injects gender as 0 or 1; see AltAhaV2Calculator#determine_gender
    CALCULATOR::CLIENT_GENDER_LINK_ID => { 'Female' => 0, 'Male' => 1 },
    # The scorecards use another question's labels for this one; pending Allegheny's confirmation (A1)
    'homeless_duration' => { 'Less than a year' => 'Less than 365', 'More than a year' => 'A year or more' },
  }.freeze

  def self.call(...) = new(...).call

  def initialize(form_definition_identifier:, paths:)
    raise ArgumentError, 'form_definition_identifier is required' if form_definition_identifier.blank?
    raise ArgumentError, 'at least one scorecard path is required' if paths.blank?

    @form_definition_identifier = form_definition_identifier
    @paths = paths
    @intercepts_seen = []
  end

  # Returns the number of rules deleted and created
  def call
    # Build and validate every rule before touching the table, so a bad row leaves the existing rules in place
    rules = @paths.flat_map { |path| build_rules(path) }
    missing = CALCULATOR::ALGORITHMS.keys - @intercepts_seen
    raise InvalidScorecardError, "No intercept row for #{missing.join(', ')}; is a scorecard missing?" if missing.any?

    RULE.transaction do
      deleted = RULE.for_form(@form_definition_identifier).where(model_version: CALCULATOR::MODEL_VERSION).delete_all
      rules.each(&:save!)
      { deleted: deleted, created: rules.size }
    end
  end

  private

  def build_rules(path)
    table = CSV.read(path, headers: true, encoding: 'bom|utf-8')
    missing_headers = REQUIRED_HEADERS - table.headers
    raise InvalidScorecardError, "#{File.basename(path)} is missing columns: #{missing_headers.join(', ')}" if missing_headers.any?

    # Line 1 is the header row
    table.each.with_index(2).filter_map do |row, line|
      build_rule(row)
    rescue InvalidScorecardError => e
      raise InvalidScorecardError, "#{File.basename(path)} line #{line}: #{e.message}"
    end
  end

  # Returns an unsaved rule, or nil for an intercept row
  def build_rule(row)
    algorithm = row['algorithm'].to_s.strip
    raise InvalidScorecardError, "unknown algorithm #{algorithm.inspect}" unless CALCULATOR::ALGORITHMS.key?(algorithm)

    weight = BigDecimal(row['weight'].to_s.strip, exception: false)
    raise InvalidScorecardError, "weight #{row['weight'].inspect} is not a number" if weight.nil?

    if row['question_id1'].to_s.strip == INTERCEPT_QUESTION_ID
      check_intercept(algorithm, row)
      return nil
    end

    primary = build_criterion(row, '1')
    secondary = build_criterion(row, '2') if slot_present?(row, '2')

    rule = RULE.new(
      form_definition_identifier: @form_definition_identifier,
      model_version: CALCULATOR::MODEL_VERSION,
      algorithm: algorithm,
      weight: weight,
      link_id: primary[:link_id],
      criteria_type: primary[:criteria_type],
      criteria_config: primary[:criteria_config],
      secondary_link_id: secondary&.dig(:link_id),
      secondary_criteria_type: secondary&.dig(:criteria_type),
      secondary_criteria_config: secondary&.dig(:criteria_config),
    )
    raise InvalidScorecardError, rule.errors.full_messages.to_sentence unless rule.valid?

    rule
  end

  # The intercepts are hand-copied into AltAhaV2Calculator, so a scorecard that disagrees stops the import
  # rather than scoring on the old baseline
  def check_intercept(algorithm, row)
    raise InvalidScorecardError, "intercept row must have criteria_type #{INTERCEPT_CRITERIA_TYPE}" unless row['criteria_type1'].to_s.strip == INTERCEPT_CRITERIA_TYPE
    raise InvalidScorecardError, 'intercept row must not have a second criterion' if slot_present?(row, '2')
    raise InvalidScorecardError, "second intercept row for #{algorithm}" if @intercepts_seen.include?(algorithm)

    expected = CALCULATOR::ALGORITHMS.fetch(algorithm)[:intercept]
    actual = Float(row['weight'].to_s.strip)
    raise InvalidScorecardError, "#{algorithm} intercept #{actual} does not match AltAhaV2Calculator's #{expected}" unless actual == expected

    @intercepts_seen << algorithm
  end

  def slot_present?(row, slot)
    return true if row["question_id#{slot}"].present?

    stray = ["transform#{slot}", "criteria_type#{slot}", "criteria_config#{slot}"].select { |col| row[col].present? }
    raise InvalidScorecardError, "#{stray.join(', ')} given without question_id#{slot}" if stray.any?

    false
  end

  def build_criterion(row, slot)
    link_id = row["question_id#{slot}"].to_s.strip
    raise InvalidScorecardError, "question_id#{slot} is blank" if link_id.blank?

    criteria_type = row["criteria_type#{slot}"].to_s.strip
    config = parse_config(row["criteria_config#{slot}"], slot)

    stored_config, expected_label = case criteria_type
    when RULE::EXACT_MATCH then exact_match_criterion(link_id, config, slot)
    when RULE::VALUE then lookup_config(VALUE_CONFIGS, config, criteria_type, slot)
    when RULE::DAYS_DIFF then lookup_config(DAYS_DIFF_CONFIGS, config, criteria_type, slot)
    else raise InvalidScorecardError, "unsupported criteria_type#{slot} #{criteria_type.inspect}"
    end

    # The labels carry no information beyond the config; checking them catches a hand-edited config that drifted
    label = row["transform#{slot}"].to_s.strip.presence
    raise InvalidScorecardError, "transform#{slot} #{label.inspect} does not match criteria_config#{slot}; expected #{expected_label.inspect}" unless label == expected_label

    { link_id: link_id, criteria_type: criteria_type, criteria_config: stored_config }
  end

  # Numeric matches on 0 and 1 are the model's zero/one indicator terms; other matches carry no label
  def exact_match_criterion(link_id, config, slot)
    raise InvalidScorecardError, "criteria_config#{slot} must have only a match_value" unless config.keys == ['match_value']

    match_value = config['match_value']
    expected_label = case match_value
    when 0 then 'zero'
    when 1 then 'one'
    end

    [{ 'match_value' => translate_answer(link_id, match_value) }, expected_label]
  end

  def translate_answer(link_id, value)
    mapping = ANSWER_VALUES[link_id]
    return value unless mapping

    mapping.fetch(value) { raise InvalidScorecardError, "#{link_id} value #{value.inspect} has no mapping; expected one of #{mapping.keys.join(', ')}" }
  end

  def lookup_config(configs, config, criteria_type, slot)
    configs.fetch(config) { raise InvalidScorecardError, "unsupported #{criteria_type} criteria_config#{slot} #{config.to_json}" }
  end

  def parse_config(raw, slot)
    config = JSON.parse(raw.presence || '{}')
    raise InvalidScorecardError, "criteria_config#{slot} must be a JSON object" unless config.is_a?(Hash)

    config
  rescue JSON::ParserError
    raise InvalidScorecardError, "criteria_config#{slot} is not valid JSON: #{raw.inspect}"
  end
end
