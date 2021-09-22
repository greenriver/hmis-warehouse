###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionEight, type: :model do
  include_context 'apr context'

  def question_8_setup_path
    'drivers/hud_apr/spec/fixtures/files/fy2021/question_8'
  end

  def question_8_setup
    warehouse = GrdaWarehouseBase.connection

    # Will use stored fixed point if one exists, instead of reprocessing the fixture, delete the fixpoint to regenerate
    if Fixpoint.exists? :hud_hmis_q8_export_app
      GrdaWarehouse::Utility.clear!
      restore_fixpoint :hud_hmis_q8_export_app
      restore_fixpoint :hud_hmis_q8_export_warehouse, connection: warehouse
    else
      setup(question_8_setup_path)
      store_fixpoint :hud_hmis_q8_export_app
      store_fixpoint :hud_hmis_q8_export_warehouse, connection: warehouse
    end
  end

  before(:all) do
    question_8_setup
    run(ph, HudApr::Generators::Apr::Fy2021::QuestionEight::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q8a: Number of Households Served' do
    it 'counts households' do
      expect(report_result.answer(question: 'Q8a', cell: 'B2').summary).to eq(8)
    end

    it 'counts households without children' do
      expect(report_result.answer(question: 'Q8a', cell: 'C2').summary).to eq(5)
    end

    it 'counts households with children and adults' do
      expect(report_result.answer(question: 'Q8a', cell: 'D2').summary).to eq(1)
    end

    it 'counts households with only children' do
      expect(report_result.answer(question: 'Q8a', cell: 'E2').summary).to eq(1)
    end

    it 'counts unknown households' do
      expect(report_result.answer(question: 'Q8a', cell: 'E2').summary).to eq(1)
    end
  end

  describe 'Q8b: Point-in-Time Count of Households on the Last Wednesday' do
    it 'counts households in January' do
      expect(report_result.answer(question: 'Q8b', cell: 'B2').summary).to eq(0)
    end

    it 'counts households in April' do
      expect(report_result.answer(question: 'Q8b', cell: 'B3').summary).to eq(1)
    end

    it 'counts households in July' do
      expect(report_result.answer(question: 'Q8b', cell: 'B4').summary).to eq(1)
    end

    it 'counts households in Oct' do
      expect(report_result.answer(question: 'Q8b', cell: 'B5').summary).to eq(0)
    end
  end
end
