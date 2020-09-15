require 'rails_helper'
require_relative 'hud_context.rb'

RSpec.describe HudApr::Generators::Shared::Fy2020::QuestionFive, type: :model do
  let!(:super_user_role) { create :can_edit_anything_super_user }
  let!(:user) { create :user, roles: [super_user_role] }
  let!(:report) do
    HudApr::Generators::Apr::Fy2020::Generator.new(
      {
        'start_date' => Date.parse('2015-1-1'),
        'end_date' => Date.parse('2015-12-31'),
        'coc_code' => 'MA-500',
        'user_id' => user.id,
      },
    )
  end

  describe 'Q5' do
    include_context 'hud context'

    before(:all) do
      setup('drivers/hud_apr/spec/fixtures/files/fy2020/q5')
    end

    after(:all) do
      cleanup
    end

    before(:each) do
      report.run!(questions: ['Q5'])
      Delayed::Worker.new.work_off
    end

    it 'counts people served' do
      expect(report_result.answer(question: 'Q5a', cell: 'B1').summary).to eq(4)
    end

    it 'counts adults' do
      expect(report_result.answer(question: 'Q5a', cell: 'B2').summary).to eq(2)
    end

    it 'counts children' do
      expect(report_result.answer(question: 'Q5a', cell: 'B3').summary).to eq(1)
    end

    it 'counts missing age' do
      expect(report_result.answer(question: 'Q5a', cell: 'B4').summary).to eq(1)
    end

    it 'counts leavers' do
      expect(report_result.answer(question: 'Q5a', cell: 'B5').summary).to eq(2)
    end

    it 'counts adult leavers' do
      expect(report_result.answer(question: 'Q5a', cell: 'B6').summary).to eq(0)
    end

    it 'counts adult head of household leavers' do
      expect(report_result.answer(question: 'Q5a', cell: 'B7').summary).to eq(2)
    end

    it 'counts stayers' do
      expect(report_result.answer(question: 'Q5a', cell: 'B8').summary).to eq(2)
    end

    it 'counts adult stayers' do
      expect(report_result.answer(question: 'Q5a', cell: 'B9').summary).to eq(2)
    end

    it 'counts veterans' do
      expect(report_result.answer(question: 'Q5a', cell: 'B10').summary).to eq(0)
    end

    it 'counts chronically homeless persons' do
      expect(report_result.answer(question: 'Q5a', cell: 'B11').summary).to eq(0)
    end

    it 'counts under 25' do
      expect(report_result.answer(question: 'Q5a', cell: 'B12').summary).to eq(1)
    end

    it 'counts under 25 with children' do
      expect(report_result.answer(question: 'Q5a', cell: 'B13').summary).to eq(0)
    end

    it 'counts adult heads of household' do
      expect(report_result.answer(question: 'Q5a', cell: 'B14').summary).to eq(2)
    end

    it 'counts child and unknown age heads of household' do
      expect(report_result.answer(question: 'Q5a', cell: 'B15').summary).to eq(2)
    end

    it 'counts heads of household and stayers over 365 days' do
      expect(report_result.answer(question: 'Q5a', cell: 'B16').summary).to eq(2)
    end
  end
end
