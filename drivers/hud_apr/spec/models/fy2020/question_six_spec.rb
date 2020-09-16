require 'rails_helper'
require_relative 'apr_context.rb'

RSpec.describe HudApr::Generators::Shared::Fy2020::QuestionSix, type: :model do
  include_context 'apr context'

  before(:all) do
    setup(default_setup_path)
    HudApr::Generators::Shared::Fy2020::QuestionSix.new(options: default_options).run!
  end

  after(:all) do
    cleanup
  end

  describe 'Q6a: Personally Identifiable Information' do
    it 'counts unknown/refused names' do
      expect(report_result.answer(question: 'Q6a', cell: 'B2').summary).to eq(0)
    end

    it 'counts missing names' do
      expect(report_result.answer(question: 'Q6a', cell: 'C2').summary).to eq(0)
    end

    it 'counts name data issues' do
      expect(report_result.answer(question: 'Q6a', cell: 'D2').summary).to eq(0)
    end

    it 'counts total name issues' do
      expect(report_result.answer(question: 'Q6a', cell: 'E2').summary).to eq(0)
    end
  end
end
