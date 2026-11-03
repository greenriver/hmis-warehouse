###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'nokogiri'
require_relative '../../../filters/criteria/shared_filter_criteria_context'

RSpec.describe GrdaWarehouse::WarehouseReports::DocumentExports::ActiveClientReportExport do
  include_context 'filter criteria setup'

  let(:filter_params) do
    {
      'start' => '2021-01-01',
      'end' => end_date.iso8601,
      'project_type_codes' => ['es'],
    }
  end
  let(:pages) { [] }

  def create_served_enrollment(project_type:)
    enrollment = create_enrollment_for_client(
      create(:grda_warehouse_hud_client),
      date: start_date + 5.days,
      first_date_in_program: start_date + 5.days,
      last_date_in_program: end_date - 5.days,
      project_type: project_type,
    )
    create(
      :service_history_service,
      service_history_enrollment: enrollment,
      record_type: 200,
      date: enrollment.first_date_in_program + 1.day,
      client_id: enrollment.client_id,
      project_type: project_type,
    )
    enrollment
  end

  before do
    create_served_enrollment(project_type: 1)
    create_served_enrollment(project_type: 3)

    # Chromium and pdfunite are external binaries; the HTML each page is built from is what we check.
    allow(PdfGenerator).to receive(:html).and_wrap_original do |original, **kwargs|
      original.call(**kwargs).tap { |html| pages << html }
    end
    allow(PdfGenerator).to receive(:render_pdf).and_return('%PDF-1.4')
    allow(PdfGenerator).to receive(:merge_inline_pdfs).and_return('%PDF-1.4')
  end

  def summary_text(query_params)
    export = described_class.new(user_id: user.id, query_string: { 'filters' => query_params, 'filter' => query_params }.to_query)
    export.perform
    expect(export.status).to eq(described_class::COMPLETED_STATUS)

    Nokogiri::HTML5(pages.first).css('section p').text.squish
  end

  it 'reports the same counts and multi-year range as the page' do
    expect(summary_text(filter_params)).to eq(
      "The following 1 clients with 1 enrollments, have at least one day of service between #{Date.new(2021, 1, 1)} and #{end_date}.".squish,
    )
  end
end
