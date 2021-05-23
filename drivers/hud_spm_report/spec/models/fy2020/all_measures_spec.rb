###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_context'

RSpec.describe HudSpmReport::Generators::Fy2020::Generator, type: :model do
  include_context 'HudSpmReport context'

  before(:all) do
    GrdaWarehouse::DataSource.where(name: 'Warehouse', short_name: 'W').first_or_create!
    @data_source = GrdaWarehouse::DataSource.where(name: 'Green River', short_name: 'GR', source_type: :sftp).first_or_create!
    import 'fy2020/measure_one', @data_source
    import 'fy2020/measure_two', @data_source
    import 'fy2020/measure_three', @data_source
    import 'fy2020/measure_four', @data_source
    import 'fy2020/measure_five', @data_source
    import 'fy2020/measure_six', @data_source
    import 'fy2020/measure_seven', @data_source

    filter = HudSpmReport::Filters::SpmFilter.new(
      shared_filter.merge(
        start: Date.parse('2015-1-1'),
        end: Date.parse('2015-12-31'),
      ),
    )

    run(filter, described_class.questions.keys)

    puts report_result.as_markdown
  end

  it 'completed successfully' do
    assert_report_completed
  end

  it 'has been provided client data' do
    assert_equal 9, @data_source.clients.count
  end

  # [
  #   ['1a', 'A1', nil],
  #   ['1a', 'C2', 2, 'persons in ES and SH'],
  #   ['1a', 'E2', 152.5, 'mean LOT in ES and SH'],
  #   ['1a', 'H2', 152.5, 'median LOT in ES and SH'],
  #   ['1b', 'C2', 2, 'persons in ES, SH, and PH'],
  #   # ['1b', 'E2', m1b_days, 'mean LOT in ES, SH, and PH'],
  #   # ['1b', 'H2', m1b_days, 'median LOT in ES, SH, and PH'],
  # ].each do |question, cell, expected_value, label|
  #   test_name = if expected_value.nil?
  #     "does not fill #{question} #{cell}"
  #   else
  #     "fills #{question} #{cell} (#{label}) with #{expected_value}"
  #   end
  #   it test_name do
  #     expect(report_result.answer(question: question, cell: cell).summary).to eq(expected_value)
  #   end
  # end
end
