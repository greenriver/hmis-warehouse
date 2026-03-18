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
      it 'writes client count then household count in the non-CoC columns' do
        rows = {}
        report.household_type_data_for_export(rows)

        # Row layout: [title, nil, client_count, hoh_count, percentage, nil, ...]
        adult_only_row = rows['_Household Types_data_Adult only Households']
        expect(adult_only_row[2]).to eq(2) # client count
        expect(adult_only_row[3]).to eq(1) # household (HoH) count
      end

      it 'writes client count then household count in the CoC columns' do
        rows = {}
        report.household_type_data_for_export(rows)

        adult_only_row = rows['_Household Types_data_Adult only Households']
        ma500_offset = coc_column_offset(rows, 'MA-500')
        expect(adult_only_row[ma500_offset]).to eq(2)     # client count (bug was: hoh_count=1)
        expect(adult_only_row[ma500_offset + 1]).to eq(1) # household (HoH) count
      end
    end
  end

  context 'with a child-only household in MA-500' do
    # Two children sharing a household. Both have known ages so the household is
    # classified as child-only (not unknown).
    let(:shared_household_id) { Hmis::Hud::Base.generate_uuid }
    let!(:child_hoh) { create_client_with_warehouse_link(dob: report_date - 12.years) }
    let!(:child_member) { create_client_with_warehouse_link(dob: report_date - 10.years) }
    # let! so enrollment records are accessible in nested before blocks
    let!(:child_hoh_enrollment) do
      create_enrollment(
        client: child_hoh,
        project: project_ma500,
        entry_date: report_date,
        relationship_to_ho_h: 1,
        household_id: shared_household_id,
      )
    end
    let!(:child_member_enrollment) do
      create_enrollment(
        client: child_member,
        project: project_ma500,
        entry_date: report_date,
        relationship_to_ho_h: 2,
        household_id: shared_household_id,
      )
    end

    before do
      create_bed_night_service(enrollment: child_hoh_enrollment, date: report_date)
      create_bed_night_service(enrollment: child_member_enrollment, date: report_date)

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
      Rails.cache.clear
    end

    # Regression coverage for a bug report where child-only household CoC columns
    # showed all zeros despite a non-zero base count in the same row.
    describe 'CoC breakdowns' do
      it 'classifies the household as child-only in the base count' do
        expect(report.household_type_client_count(:only_children)).to eq(2)
        expect(report.household_type_hoh_count(:only_children)).to eq(1)
      end

      it 'reports non-zero client count for the CoC containing the household' do
        expect(report.household_type_client_count(:only_children, :'MA-500')).to eq(2)
      end

      it 'reports non-zero household count for the CoC containing the household' do
        expect(report.household_type_hoh_count(:only_children, :'MA-500')).to eq(1)
      end

      it 'reports zero counts for a CoC with no child-only households' do
        expect(report.household_type_client_count(:only_children, :'MA-501')).to eq(0)
        expect(report.household_type_hoh_count(:only_children, :'MA-501')).to eq(0)
      end

      it 'writes non-zero CoC columns in the export row' do
        rows = {}
        report.household_type_data_for_export(rows)

        child_only_row = rows['_Household Types_data_Child only Households']
        expect(child_only_row[2]).to eq(2) # base client count
        expect(child_only_row[3]).to eq(1) # base household (HoH) count

        ma500_offset = coc_column_offset(rows, 'MA-500')
        ma501_offset = coc_column_offset(rows, 'MA-501')
        expect(child_only_row[ma500_offset]).to eq(2)     # MA-500 client count
        expect(child_only_row[ma500_offset + 1]).to eq(1) # MA-500 household (HoH) count
        expect(child_only_row[ma501_offset]).to eq(0)     # MA-501 client count
        expect(child_only_row[ma501_offset + 1]).to eq(0) # MA-501 household count
      end
    end

    # Documents the behavior when EnrollmentCoC is NULL on child-only household enrollments.
    #
    # FilterForCocs deliberately passes NULL EnrollmentCoC through the base household scope
    # (so data-quality gaps don't silently drop clients from totals). However, the per-CoC
    # scope uses `in_enrollment_coc` (INNER JOIN + exact equality), which excludes NULLs.
    # The result: clients show up in the base count (column D) but every CoC column is zero.
    #
    # This matches the reported production symptom for child-only households. The root cause
    # is missing EnrollmentCoC data in the source system, not a code bug.
    describe 'with nil EnrollmentCoC' do
      before do
        # create_enrollment sets enrollment_coc from the project's coc_code by default;
        # null it out before rebuilding service history to reproduce the missing-data condition.
        child_hoh_enrollment.update!(enrollment_coc: nil)
        child_member_enrollment.update!(enrollment_coc: nil)

        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
        Rails.cache.clear
      end

      it 'still counts the household in the base (non-CoC) totals' do
        # FilterForCocs explicitly allows NULL EnrollmentCoC through the base scope so
        # clients are not silently dropped from totals due to missing data.
        expect(report.household_type_client_count(:only_children)).to eq(2)
        expect(report.household_type_hoh_count(:only_children)).to eq(1)
      end

      it 'returns zero for all CoC-specific counts' do
        # in_enrollment_coc uses INNER JOIN + exact equality, so NULL EnrollmentCoC
        # is excluded from every per-CoC breakdown.
        expect(report.household_type_client_count(:only_children, :'MA-500')).to eq(0)
        expect(report.household_type_hoh_count(:only_children, :'MA-500')).to eq(0)
      end

      it 'shows non-zero base columns but zero CoC columns in the export row' do
        rows = {}
        report.household_type_data_for_export(rows)

        child_only_row = rows['_Household Types_data_Child only Households']
        ma500_offset = coc_column_offset(rows, 'MA-500')
        expect(child_only_row[2]).to eq(2)               # base client count is non-zero
        expect(child_only_row[3]).to eq(1)               # base household count is non-zero
        expect(child_only_row[ma500_offset]).to eq(0)     # MA-500 client count — zero due to nil EnrollmentCoC
        expect(child_only_row[ma500_offset + 1]).to eq(0) # MA-500 household count — zero
      end
    end
  end
end
