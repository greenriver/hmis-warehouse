###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::AltAhaV2ScorecardImporter, type: :model do
  let(:dir) { Dir.mktmpdir }
  after { FileUtils.remove_entry(dir) }

  let(:intercepts) do
    HmisExternalApis::AcHmis::AltAhaV2Calculator::ALGORITHMS.transform_values { |config| config[:intercept] }
  end

  let!(:stale_v2_rule) { create(:hmis_scoring_rule, :v2, form_definition_identifier: 'test_form', algorithm: 'alt_aha_1') }
  let!(:v1_rule) { create(:hmis_scoring_rule, :v1, form_definition_identifier: 'test_form', algorithm: 'alt_aha_1') }
  let!(:other_form_v2_rule) { create(:hmis_scoring_rule, :v2, form_definition_identifier: 'other_form', algorithm: 'alt_aha_1') }

  def import(paths)
    described_class.call(form_definition_identifier: 'test_form', paths: paths)
  end

  # One scorecard per algorithm, each with its intercept row and a single paired term
  def scorecard_paths(intercepts_by_algorithm)
    intercepts_by_algorithm.map do |algorithm, intercept|
      write_scorecard(algorithm, [intercept_row(algorithm, intercept), term_row(algorithm)])
    end
  end

  def write_scorecard(algorithm, rows)
    headers = described_class::REQUIRED_HEADERS
    path = File.join(dir, "#{algorithm}.csv")
    CSV.open(path, 'w') do |csv|
      csv << headers
      rows.each { |row| csv << headers.map { |header| row[header] } }
    end
    path
  end

  def intercept_row(algorithm, intercept)
    {
      'algorithm' => algorithm,
      'question_id1' => '__INTERCEPT__',
      'criteria_type1' => 'constant',
      'criteria_config1' => '{}',
      'weight' => intercept.to_s,
    }
  end

  def term_row(algorithm)
    {
      'algorithm' => algorithm,
      'question_id1' => 'client_demographics_gender',
      'criteria_type1' => 'exact_match',
      'criteria_config1' => '{"match_value": "Female"}',
      'question_id2' => 'homeless_duration',
      'criteria_type2' => 'exact_match',
      'criteria_config2' => '{"match_value": "More than a year"}',
      'weight' => '0.25',
    }
  end

  it 'replaces only the version 2 rules for the identifier when every intercept matches' do
    result = import(scorecard_paths(intercepts))

    expect(result).to eq(deleted: 1, created: 4)
    imported = Hmis::Scoring::Rule.for_form('test_form').where(model_version: 2)
    expect(imported.pluck(:algorithm)).to contain_exactly('alt_aha_1', 'alt_aha_2', 'alt_aha_3', 'alt_aha_4')
    expect(Hmis::Scoring::Rule.exists?(stale_v2_rule.id)).to be false
    expect(Hmis::Scoring::Rule.exists?(v1_rule.id)).to be true
    expect(Hmis::Scoring::Rule.exists?(other_form_v2_rule.id)).to be true

    rule = imported.find_by!(algorithm: 'alt_aha_1')
    expect(rule.criteria_config).to eq('match_value' => 0)
    expect(rule.secondary_criteria_config).to eq('match_value' => 'A year or more')
  end

  it 'fails without writing when an intercept disagrees with the calculator constant' do
    tampered = intercepts.merge('alt_aha_2' => intercepts['alt_aha_2'] + 0.0001)

    expect { import(scorecard_paths(tampered)) }.to raise_error(
      described_class::InvalidScorecardError,
      /alt_aha_2\.csv line 2: alt_aha_2 intercept .* does not match/,
    )
    expect(Hmis::Scoring::Rule.exists?(stale_v2_rule.id)).to be true
  end

  it 'fails when an algorithm has no intercept row' do
    expect { import(scorecard_paths(intercepts.except('alt_aha_4'))) }.to raise_error(
      described_class::InvalidScorecardError,
      /No intercept row for alt_aha_4/,
    )
    expect(Hmis::Scoring::Rule.exists?(stale_v2_rule.id)).to be true
  end
end
