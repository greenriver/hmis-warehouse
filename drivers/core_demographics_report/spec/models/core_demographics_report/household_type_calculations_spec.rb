###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'

# HouseholdTypeCalculations is mixed into both Core and DemographicSummary::Report.
# CoC-level breakdowns are only active on DemographicSummary::Report when
# should_calculate_coc_breakdowns is set to true, so that class is used here to
# exercise the CoC export path.
RSpec.describe CoreDemographicsReport::HouseholdTypeCalculations, type: :model do
  include_context 'HUD enrollment builders'

  let(:report_date) { Date.current }
  let(:project_ma500) { create_project(project_type: 1, coc_code: 'MA-500') }
  let(:project_ma501) { create_project(project_type: 1, coc_code: 'MA-501') }
  let(:filter) do
    Filters::FilterBase.new(
      user: user,
      start: report_date.beginning_of_year,
      end: report_date.end_of_year,
      project_type_codes: HudHelper.util.homeless_project_type_codes,
      enforce_one_year_range: false,
      require_service_during_range: true,
      coc_codes: ['MA-500', 'MA-501'],
    )
  end
  let(:report) do
    CoreDemographicsReport::DemographicSummary::Report.new(filter).tap do |r|
      r.should_calculate_coc_breakdowns = true
    end
  end

  before do
    user.add_viewable(project_ma500)
    user.add_viewable(project_ma501)
  end

  # Returns the start index of the given CoC's columns in a data row, derived from
  # the header row so assertions remain correct if coc_codes order changes.
  def coc_column_offset(rows, coc_code)
    rows['*Household Types'].index("#{coc_code} Client")
  end

  # Two adults sharing a household: client_count=2, hoh_count=1.
  # Tests that the two count methods return distinct values and that the export
  # writes them to the correct columns.
  context 'with an adult-only household in MA-500' do
    let(:shared_household_id) { Hmis::Hud::Base.generate_uuid }
    let!(:hoh_client) { create_client_with_warehouse_link(dob: report_date - 35.years) }
    let!(:member_client) { create_client_with_warehouse_link(dob: report_date - 30.years) }

    before do
      hoh_enrollment = create_enrollment(
        client: hoh_client,
        project: project_ma500,
        entry_date: report_date,
        relationship_to_ho_h: 1,
        household_id: shared_household_id,
      )
      member_enrollment = create_enrollment(
        client: member_client,
        project: project_ma500,
        entry_date: report_date,
        relationship_to_ho_h: 2,
        household_id: shared_household_id,
      )
      create_bed_night_service(enrollment: hoh_enrollment, date: report_date)
      create_bed_night_service(enrollment: member_enrollment, date: report_date)

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
      Rails.cache.clear
    end

    describe '#household_type_hoh_count and #household_type_client_count' do
      it 'counts all household members via household_type_client_count' do
        expect(report.household_type_client_count(:without_children)).to eq(2)
      end

      it 'counts only heads of household via household_type_hoh_count' do
        expect(report.household_type_hoh_count(:without_children)).to eq(1)
      end
    end

    describe '#household_type_data_for_export' do
      it 'writes counts and percentage to the base and CoC columns' do
        rows = {}
        report.household_type_data_for_export(rows)

        # Row layout: [title, nil, client_count, hoh_count, percentage, nil, ...]
        adult_only_row = rows['_Household Types_data_Adult only Households']
        expect(adult_only_row[2]).to eq(2) # client count
        expect(adult_only_row[3]).to eq(1) # household (HoH) count
        expect(adult_only_row[4]).to eq(1.0) # percentage (1/1)

        ma500_offset = coc_column_offset(rows, 'MA-500')
        expect(adult_only_row[ma500_offset]).to eq(2)     # CoC client count
        expect(adult_only_row[ma500_offset + 1]).to eq(1) # CoC household count
        expect(adult_only_row[ma500_offset + 2]).to eq(1.0) # CoC percentage
      end
    end
  end

  # Both reports use the same household type calculations. Verify integration and detail_hash.
  [
    ['Core Demographics', CoreDemographicsReport::Core],
    ['Demographic Summary', CoreDemographicsReport::DemographicSummary::Report],
  ].each do |report_name, report_class|
    describe "#{report_name} integration" do
      let(:test_report) { report_class.new(filter) }

      it 'includes household types in section types' do
        section_types = report_class.available_section_types
        expect(section_types).to include('household_types')
      end

      it 'includes household detail hash in detail_hash' do
        detail_hash = test_report.detail_hash

        # Verify example household detail keys are present
        expect(detail_hash).to have_key('household_type_without_children')
        expect(detail_hash).to have_key('household_type_client_without_children')

        # Verify structure of a detail entry
        detail = detail_hash['household_type_without_children']
        expect(detail).to be_a(Hash)
        expect(detail).to have_key(:title)
        expect(detail).to have_key(:headers)
        expect(detail).to have_key(:columns)
        expect(detail).to have_key(:scope)
        expect(detail[:title]).to include('Household Type')
        expect(detail[:scope]).to be_a(Proc)
      end
    end
  end
end
