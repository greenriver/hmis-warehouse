# frozen_string_literal: true

RSpec.shared_examples 'a hud cell detail export' do
  describe '#authorized?' do
    let(:other_user) { create(:user) }

    before do
      allow(user).to receive(:can_view_hud_reports?).and_return(true)
    end

    it 'is authorized if the user owns the report' do
      report.update!(user_id: user.id)
      expect(export.authorized?).to be true
    end

    it 'is authorized if the user can view all reports' do
      report.update!(user_id: other_user.id)
      allow(user).to receive(:can_view_all_hud_reports?).and_return(true)
      expect(export.authorized?).to be true
    end

    it 'is not authorized if the user does not own the report and cannot view all' do
      report.update!(user_id: other_user.id)
      allow(user).to receive(:can_view_all_hud_reports?).and_return(false)
      expect(export.authorized?).to be false
    end

    it 'is not authorized if the user cannot view hud reports at all' do
      allow(user).to receive(:can_view_hud_reports?).and_return(false)
      expect(export.authorized?).to be false
    end
  end

  describe '#download_title' do
    it 'includes the drilldown name and "Cell Detail"' do
      expect(export.download_title).to include('Cell Detail')
      # The drilldown name comes from the builder, so we verify it's present
      expect(export.download_title).to include(export.send(:builder).drilldown.name)
    end
  end

  describe '#perform' do
    let(:result) { double('Result', filename: 'test.xlsx', data: 'binary-data') }

    it 'calls the builder and updates status' do
      # We mock the builder to avoid deep integration tests here,
      # as we want to test the orchestration in the base class.
      allow(export.send(:builder)).to receive(:call).and_return(result)

      export.perform

      expect(export.filename).to eq('test.xlsx')
      expect(export.file_data).to eq('binary-data')
      expect(export.mime_type).to eq(DocumentExportBehavior::EXCEL_MIME_TYPE)
      expect(export.status).to eq(DocumentExportBehavior::COMPLETED_STATUS)
    end
  end
end
