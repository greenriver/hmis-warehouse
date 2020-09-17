RSpec.shared_examples 'question six' do
  describe 'Q6: Data Quality' do
    before(:all) do
      HudApr::Generators::Shared::Fy2020::QuestionSix.new(options: default_options).run!
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

    describe 'Q6b: Data Quality: Universal Data Elements' do
    end

    describe 'Q6c: Data Quality: Income and Housing Data Quality' do
    end

    describe 'Q6d: Data Quality: Chronic Homelessness' do
    end

    describe 'Q6e: Data Quality: Timeliness' do
    end

    describe 'Q6f: Data Quality: Inactive Records: Street Outreach and Emergency Shelter' do
    end
  end
end
