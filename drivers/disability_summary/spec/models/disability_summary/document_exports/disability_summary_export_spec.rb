###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DisabilitySummary::DocumentExports::DisabilitySummaryExport, type: :model do
  let(:collection) { create(:collection) }
  let(:report_definition) { create(:touch_point_report, url: DisabilitySummary::DisabilitySummaryReport.url, name: 'Disability Summary') }
  let(:user) { create(:acl_user) }
  let(:query_string) { { filters: { start: 1.year.ago.to_date.to_s, end: Date.current.to_s } }.to_query }

  before do
    Rails.cache.clear
    collection.set_viewables({ reports: [report_definition.id] })
    setup_access_control(user, create(:role, name: 'assigned reports', can_view_assigned_reports: true, can_view_all_reports: true), collection)
  end

  let(:export) { described_class.new(user: user, query_string: query_string) }

  it 'is authorized for a user with the report assigned' do
    expect(export.authorized?).to be(true)
  end

  it 'is not authorized without the report assigned' do
    other = create(:acl_user)
    setup_access_control(other, create(:role, name: 'unassigned all reports', can_view_all_reports: true, can_view_assigned_reports: true), create(:collection))

    expect(described_class.new(user: other, query_string: query_string).authorized?).to be(false)
  end

  it 'renders the report view and marks the export completed' do
    pdf_file = Tempfile.new(['disability_summary', '.pdf'])
    pdf_file.write('%PDF-fake')
    pdf_file.rewind
    pdf_generator = instance_double(PdfGenerator)
    allow(PdfGenerator).to receive(:new).and_return(pdf_generator)
    allow(pdf_generator).to receive(:perform).and_yield(pdf_file).and_return(true)
    export.status = GrdaWarehouse::DocumentExport::PENDING_STATUS
    export.save!

    export.perform

    expect(export.reload.status).to eq(GrdaWarehouse::DocumentExport::COMPLETED_STATUS)
    expect(export.file_data).to eq('%PDF-fake')
  ensure
    pdf_file&.close!
  end
end
