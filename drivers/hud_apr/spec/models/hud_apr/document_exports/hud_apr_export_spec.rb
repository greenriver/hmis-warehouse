###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudApr::DocumentExports::HudAprExport, type: :model do
  let(:user) { create(:user) }
  let(:report_name) { HudApr::Generators::Apr::Fy2024::Generator.title }

  describe '#perform' do
    context 'when the referenced report cannot be found' do
      let(:export) { described_class.new(user: user, query_string: { id: 0 }.to_query) }

      it 'skips rendering and marks the export as errored instead of raising' do
        expect(Rails.logger).to receive(:warn).with(/report 0 not found/)

        expect { export.perform }.not_to raise_error

        expect(export.status).to eq(DocumentExportBehavior::ERROR_STATUS)
        expect(export.file_data).to be_nil
      end
    end

    context 'when the report belongs to a different user' do
      let(:owner) { create(:user) }
      let(:report) { create(:hud_reports_report_instance, user: owner, report_name: report_name) }
      let(:export) { described_class.new(user: user, query_string: { id: report.id }.to_query) }

      it 'treats it as not found instead of exporting a report owned by another user' do
        expect(Rails.logger).to receive(:warn).with(/report #{report.id} not found/)

        export.perform

        expect(export.status).to eq(DocumentExportBehavior::ERROR_STATUS)
        expect(export.file_data).to be_nil
      end
    end

    context 'when the report is found' do
      let(:report) { create(:hud_reports_report_instance, user: user, report_name: report_name) }
      let(:export) { described_class.new(user: user, query_string: { id: report.id }.to_query) }
      let(:pdf_tempfile) do
        Tempfile.new(['apr', '.pdf']).tap do |file|
          file.write('%PDF-fake')
          file.rewind
        end
      end

      after { pdf_tempfile.close! }

      it 'renders the matched report through its generator and marks the export completed' do
        scoped_renderer = instance_double(ActionController::Renderer)
        expect(HudApr::AprsController).to receive(:renderer).
          and_return(instance_double(ActionController::Renderer, new: scoped_renderer))
        expect(scoped_renderer).to receive(:render).with(
          'hud_reports/download',
          layout: 'layouts/hud_report_export',
          assigns: { report: report, generator: HudApr::Generators::Apr::Fy2024::Generator },
          formats: [:html],
        ).and_return('<html></html>')

        pdf_double = instance_double(PdfGenerator)
        expect(PdfGenerator).to receive(:new).and_return(pdf_double)
        expect(pdf_double).to receive(:perform).
          with(html: '<html></html>', file_name: a_string_matching(/\Av1\.2 APR FY 2024-/)).
          and_yield(pdf_tempfile).
          and_return(true)

        export.perform

        expect(export.status).to eq(DocumentExportBehavior::COMPLETED_STATUS)
        expect(export.file_data).to eq('%PDF-fake')
      end
    end
  end

  describe '#authorized?' do
    let(:export) { described_class.new(user: user, query_string: { id: report_id }.to_query) }

    context 'when the user can view all HUD reports' do
      before { user.legacy_roles << create(:role, can_view_all_hud_reports: true) }

      let(:report_id) { 0 }

      it 'is authorized even though the report cannot be found' do
        expect(export.authorized?).to eq(true)
      end
    end

    context 'when the user can only view their own HUD reports and owns the report' do
      before { user.legacy_roles << create(:role, can_view_own_hud_reports: true) }

      let(:report) { create(:hud_reports_report_instance, user: user, report_name: report_name) }
      let(:report_id) { report.id }

      it 'is authorized' do
        expect(export.authorized?).to eq(true)
      end
    end

    context 'when the user can only view their own HUD reports and the report cannot be found' do
      before { user.legacy_roles << create(:role, can_view_own_hud_reports: true) }

      let(:report_id) { 0 }

      it 'is not authorized' do
        expect(export.authorized?).to eq(false)
      end
    end

    context 'when the user has no HUD report permissions' do
      let(:report) { create(:hud_reports_report_instance, user: user, report_name: report_name) }
      let(:report_id) { report.id }

      it 'is not authorized even though the report exists and belongs to them' do
        expect(export.authorized?).to eq(false)
      end
    end
  end
end
