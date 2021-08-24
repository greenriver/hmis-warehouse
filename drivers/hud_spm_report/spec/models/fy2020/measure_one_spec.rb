###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_context'

RSpec.describe HudSpmReport::Generators::Fy2020::MeasureOne, type: :model do
  include_context 'HudSpmReport context'

  describe 'measure one example' do
    before(:all) do
      setup('fy2020/measure_one')

      # puts described_class.question_number
      run(default_filter, described_class.question_number)
    end

    it 'has been provided client data' do
      assert_equal 1, @data_source.clients.count
    end

    it 'completed successfully' do
      assert_report_completed
    end

    m1a_days = (Date.parse('2016-5-1') - Date.parse('2016-2-1')).to_i + (Date.parse('2016-11-1') - Date.parse('2016-9-1')).to_i
    m1b_days = (Date.parse('2016-5-1') - Date.parse('2015-8-1')).to_i + (Date.parse('2016-11-1') - Date.parse('2016-7-1')).to_i

    [
      ['1a', 'A1', nil],
      ['1a', 'C2', 1, 'persons in ES and SH'],
      ['1a', 'E2', m1a_days, 'mean LOT in ES and SH'],
      ['1a', 'H2', m1a_days, 'median LOT in ES and SH'],
      ['1b', 'C2', 1, 'persons in ES, SH, and PH'],
      ['1b', 'E2', m1b_days, 'mean LOT in ES, SH, and PH'],
      ['1b', 'H2', m1b_days, 'median LOT in ES, SH, and PH'],
    ].each do |question, cell, expected_value, label|
      test_name = if expected_value.nil?
        "does not fill #{question} #{cell}"
      else
        "fills #{question} #{cell} (#{label}) with #{expected_value}"
      end
      it test_name do
        expect(report_result.answer(question: question, cell: cell).summary).to eq(expected_value)
      end
    end
  end

  describe 'measure one additional tests' do
    before(:all) do
      cleanup
      setup('fy2020/measure_one_additional')

      # puts described_class.question_number
      run(default_filter, described_class.question_number)
    end

    it 'has been provided client data' do
      assert_equal 6, @data_source.clients.count
    end

    it 'completed successfully' do
      assert_equal 'Completed', report_result.state
      assert_equal [described_class.question_number], report_result.build_for_questions
      assert report_result.remaining_questions.none?
    end

    def client_included(question, cell, personal_id)
      c = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: personal_id)
      report_result.answer(question: question, cell: cell).members.any? do |m|
        yield m, c
      end
    end

    def refute_client_included(question:, cell:, personal_id:, &condition)
      refute client_included(question, cell, personal_id, &condition)
    end

    def assert_client_included(question:, cell:, personal_id:, &condition)
      assert client_included(question, cell, personal_id, &condition)
    end

    it 'excludes client 1 (1a)' do
      refute_client_included(question: '1a', cell: 'C2', personal_id: '1') do |m, c|
        m.client_id == c.id
      end
    end

    it 'counts 27 days for client 2 (1b)' do
      assert_client_included(question: '1a', cell: 'C2', personal_id: '2') do |m, c|
        m.client_id == c.id && m.universe_membership.m1a_es_sh_days == 27
      end
    end

    it 'counts 27 days for client 3 (1c)' do
      assert_client_included(question: '1a', cell: 'C2', personal_id: '3') do |m, c|
        m.client_id == c.id && m.universe_membership.m1a_es_sh_days == 27
      end
    end

    it 'counts 2 days (in a leap year) for client 4 (1d)' do
      assert_client_included(question: '1a', cell: 'C2', personal_id: '4') do |m, c|
        # Note 2016 is a leap year, so the client receives 2/28 and 2/29
        m.client_id == c.id && m.universe_membership.m1a_es_sh_days == 2
      end
    end

    it 'counts 29 days (in a leap year) for client 5 (1e)' do
      assert_client_included(question: '1a', cell: 'C2', personal_id: '5') do |m, c|
        # Note 2016 is a leap year, so the client receives 2/28 and 2/29
        m.client_id == c.id && m.universe_membership.m1a_es_sh_days == 29
      end
    end

    it 'client 6 has no stays (1f)' do
      refute_client_included(question: '1a', cell: 'C2', personal_id: '6') do |m, c|
        m.client_id == c.id
      end
    end

    [
      ['1a', 'C2', 4, 'persons in ES and SH'],
      ['1a', 'E2', 21.25, 'mean LOT in ES and SH'],
      ['1a', 'H2', 27.0, 'median LOT in ES and SH'],
      ['1b', 'C2', 4, 'persons in ES, SH, and PH'],
      ['1b', 'E2', 21.25, 'mean LOT in ES, SH, and PH'],
      ['1b', 'H2', 27.0, 'median LOT in ES, SH, and PH'],
    ].each do |question, cell, expected_value, label|
      test_name = if expected_value.nil?
        "does not fill #{question} #{cell}"
      else
        "fills #{question} #{cell} (#{label}) with #{expected_value}"
      end
      it test_name do
        expect(report_result.answer(question: question, cell: cell).summary).to eq(expected_value)
      end
    end
  end
end
