###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_context'

RSpec.describe HudSpmReport::Generators::Fy2020::MeasureThree, type: :model do
  include_context 'HudSpmReport context'

  before(:all) do
    setup('fy2020/measure_three')
    filter = ::Filters::HudFilterBase.new(
      shared_filter.merge(
        start: Date.parse('2015-1-1'),
        end: Date.parse('2015-12-31'),
      ),
    )
    run(filter, described_class.question_number)
  end

  it 'has been provided client data' do
    assert_equal 6, @data_source.clients.count
  end

  it 'completed successfully' do
    assert_report_completed
  end

  [
    ['3.1', 'A1', nil],
    ['3.1', 'C2', nil], # instructions tell us to leave blank for a human to fill in
    ['3.1', 'C3', nil],
    ['3.1', 'C4', nil],
    ['3.1', 'C5', nil],
    ['3.1', 'C6', nil],
    ['3.1', 'C7', nil],

    ['3.2', 'A1', nil],
    ['3.2', 'C2', 3, 'unduplicated total sheltered homeless persons'],
    ['3.2', 'C3', 1, 'emergency shelter'],
    ['3.2', 'C4', 1, 'safe haven'],
    ['3.2', 'C5', 1, 'transitional housing'],
  ].each do |question, cell, expected_value, label|
    test_name = if expected_value.nil?
      "does not fill #{question} #{cell} #{label}".strip
    else
      "fills #{question} #{cell} (#{label}) with #{expected_value}"
    end
    it test_name do
      expect(report_result.answer(question: question, cell: cell).summary).to eq(expected_value)
    end
  end

  def client_included(question, cell, personal_id)
    c = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: personal_id)
    report_result.answer(question: question, cell: cell).members.any? do |m|
      yield m, c
    end
  end

  def assert_client_included(question:, cell:, personal_id:, &condition)
    assert client_included(question, cell, personal_id, &condition)
  end

  it 'counts client 4 in ES' do
    assert_client_included(question: '3.2', cell: 'C3', personal_id: '4') do |m, c|
      m.client_id == c.id && m.universe_membership.m3_active_project_types.include?(1)
    end
  end

  it 'counts client 5 in SH' do
    assert_client_included(question: '3.2', cell: 'C4', personal_id: '5') do |m, c|
      m.client_id == c.id && m.universe_membership.m3_active_project_types.include?(8)
    end
  end

  it 'counts client 6 in TH' do
    assert_client_included(question: '3.2', cell: 'C5', personal_id: '6') do |m, c|
      m.client_id == c.id && m.universe_membership.m3_active_project_types.include?(2)
    end
  end
end
