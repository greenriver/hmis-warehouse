###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../shared_contexts/hud_enrollment_builders'
require_relative '../../../shared_contexts/performance_dashboard_helpers'

RSpec.describe PerformanceDashboards::Overview, type: :model do
  include_context 'HUD enrollment builders'
  include_context 'performance dashboard helpers'

  let(:start_date) { Date.parse('2024-01-01') }
  let(:end_date) { Date.parse('2024-12-31') }
  let(:filter) do
    Filters::PerformanceDashboard.new(
      user: user,
      start: start_date,
      end: end_date,
      project_type_codes: HudHelper.util.homeless_project_type_codes,
      sub_population: :clients,
      enforce_one_year_range: false,
      require_service_during_range: true,
    )
  end
  let!(:project) { create_project(project_type: 1, coc_code: 'MA-500') }
  let!(:report) { described_class.new(filter) }

  before do
    user.add_viewable(project)
  end

  describe 'coc_bucket' do
    it 'maps nil and blank to "Data not collected"' do
      expect(report.coc_bucket(nil)).to eq('Data not collected')
      expect(report.coc_bucket('')).to eq('Data not collected')
    end

    it 'returns the CoC code when present' do
      expect(report.coc_bucket('MA-500')).to eq('MA-500')
    end
  end

  describe 'coc_bucket_titles' do
    it 'includes "Data not collected" for drill-down sub_key lookup' do
      titles = report.coc_bucket_titles
      expect(titles).to have_key('Data not collected')
      expect(titles['Data not collected']).to eq('Data not collected')
    end
  end

  describe '#enrolled_by_coc' do
    context 'with an enrollment that has no CoC (Data not collected)' do
      let!(:client_without_coc) do
        client = create_client_with_warehouse_link
        enrollment = create_enrollment(
          client: client,
          project: project,
          entry_date: start_date + 10.days,
          enrollment_coc: nil,
        )
        create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
        client
      end

      before do
        client_without_coc.enrollments.first.update!(EnrollmentCoC: nil)
        rebuild_service_history_and_clear_cache
      end

      it 'buckets enrollments with nil enrollment_coc as "Data not collected"' do
        buckets = report.enrolled_by_coc
        expect(buckets).to have_key('Data not collected')
        expect(buckets['Data not collected']).to include(client_without_coc.warehouse_client_source.destination_id)
      end

      it 'returns client details when drilling down to "Data not collected"' do
        details = report.detail_for(
          key: :enrolled,
          sub_key: 'Data not collected',
          breakdown: 'By CoC',
          coc: true,
        )
        expect(details).to be_present
        expect(details.keys).to include(client_without_coc.warehouse_client_source.destination_id)
      end
    end
  end
end
