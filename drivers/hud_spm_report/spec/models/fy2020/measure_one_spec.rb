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
      GrdaWarehouse::Utility.clear!
      setup('fy2020/measure_one')

      # puts described_class.question_number
      run(default_filter, described_class.question_number)
    end

    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      cleanup_files
      Delayed::Job.delete_all
    end

    it 'has been provided client data' do
      assert_equal 1, @data_source.clients.count
    end

    it 'completed successfully' do
      assert_equal 'Completed', report_result.state
      assert_equal [described_class.question_number], report_result.build_for_questions
      assert report_result.remaining_questions.none?
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
      GrdaWarehouse::Utility.clear!
      setup('fy2020/measure_one_additional')

      # puts described_class.question_number
      run(default_filter, described_class.question_number)
    end

    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      cleanup_files
      Delayed::Job.delete_all
    end

    it 'has been provided client data' do
      assert_equal 6, @data_source.clients.count
    end

    it 'completed successfully' do
      assert_equal 'Completed', report_result.state
      assert_equal [described_class.question_number], report_result.build_for_questions
      assert report_result.remaining_questions.none?
    end

    it 'excludes client 1 (1a)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '1')
      expect(report_result.support['onea_c2']['support']['counts'].select { |id, _| id == client.id }).to be_empty
    end

    it 'counts 27 days for client 2 (1b)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '2')
      expect(report_result.support['onea_c2']['support']['counts'].select { |id, _| id == client.id }.first[2]).to eq(27)
    end

    it 'counts 27 days for client 3 (1c)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '3')
      expect(report_result.support['onea_c2']['support']['counts'].select { |id, _| id == client.id }.first[2]).to eq(27)
    end

    it 'counts 1 days for client 4 (1d)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '4')
      # Note 2016 is a leap year, so the client receives 2/28 and 2/29
      expect(report_result.support['onea_c2']['support']['counts'].select { |id, _| id == client.id }.first[2]).to eq(2)
    end

    it 'counts 28 days for client 5 (1e)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '5')
      # Note 2016 is a leap year
      expect(report_result.support['onea_c2']['support']['counts'].select { |id, _| id == client.id }.first[2]).to eq(29)
    end

    it 'client 6 has no stays (1f)' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(PersonalID: '6')
      expect(report_result.support['onea_c2']['support']['counts'].select { |id, _| id == client.id }).to be_empty
    end

    [
      ['1a', 'C2', 4, 'persons in ES and SH'],
      ['1a', 'E2', 21.25, 'mean LOT in ES and SH'],
      ['1a', 'H2', 27.0, 'median LOT in ES and SH'],
      ['1b', 'C2', 4, 'persons in ES, SH, and PH'],
      ['1b', 'E2', 29.0, 'mean LOT in ES, SH, and PH'],
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
