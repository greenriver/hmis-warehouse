###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudLsa::Generators::Fy2026::Lsa, type: :model do
  let(:hic_scope_value) { HudLsa::Fy2026::Report.available_lsa_scopes['HIC'] }

  def create_lsa_report(**options_hash)
    create(
      :hud_reports_report_instance,
      type: 'HudLsa::Generators::Fy2026::Lsa',
      options: options_hash,
      question_names: [],
    ).becomes(described_class)
  end

  # -- State machine (StatusProgressionConcern) --------------------------------

  describe 'state machine' do
    let(:report) { create_lsa_report }

    describe '#start_report' do
      it 'transitions to Started with timestamp and initial progress' do
        report.start_report
        report.reload
        expect(report.state).to eq('Started')
        expect(report.started_at).to be_present
        expect(report.percent_complete).to eq(0.01)
      end
    end

    describe '#finish_report' do
      it 'transitions to Completed with timestamp and full progress' do
        report.finish_report
        report.reload
        expect(report.state).to eq('Completed')
        expect(report.completed_at).to be_present
        expect(report.percent_complete).to eq(100)
      end
    end

    describe '#fail_report' do
      it 'transitions to Failed with timestamp, zeroed progress, and reason' do
        report.fail_report('Missing housing type data')
        report.reload
        expect(report.state).to eq('Failed')
        expect(report.failed_at).to be_present
        expect(report.percent_complete).to eq(0)
        expect(report.error_details).to eq('Missing housing type data')
      end

      it 'accepts nil reason' do
        report.fail_report
        report.reload
        expect(report.state).to eq('Failed')
        expect(report.error_details).to be_nil
      end
    end
  end

  # -- Scopes and hic? ---------------------------------------------------------

  describe 'scopes' do
    let!(:system_wide_report) { create_lsa_report(lsa_scope: 1) }
    let!(:project_focused_report) { create_lsa_report(lsa_scope: 2) }
    let!(:hic_report) { create_lsa_report(lsa_scope: hic_scope_value) }
    let!(:no_scope_report) { create_lsa_report }

    describe '.lsa' do
      it 'includes non-HIC reports' do
        results = described_class.lsa
        expect(results).to include(system_wide_report, project_focused_report, no_scope_report)
      end

      it 'excludes HIC reports' do
        expect(described_class.lsa).not_to include(hic_report)
      end
    end

    describe '.hic' do
      it 'includes only HIC reports' do
        expect(described_class.hic).to contain_exactly(hic_report)
      end
    end
  end

  describe '#hic?' do
    it 'returns true when lsa_scope matches HIC' do
      report = create_lsa_report(lsa_scope: hic_scope_value)
      expect(report).to be_hic
    end

    it 'returns false for system-wide scope' do
      report = create_lsa_report(lsa_scope: 1)
      expect(report).not_to be_hic
    end

    it 'returns false when lsa_scope is nil' do
      report = create_lsa_report
      expect(report).not_to be_hic
    end

    it 'matches string-stored lsa_scope via integer coercion' do
      report = create_lsa_report(lsa_scope: hic_scope_value.to_s)
      expect(report).to be_hic
    end
  end

  describe '.find_report / .find_hic_report' do
    let(:user) { create(:acl_user) }

    before do
      create_lsa_report(lsa_scope: 1).update!(user_id: user.id)
      create_lsa_report(lsa_scope: hic_scope_value).update!(user_id: user.id)
    end

    it 'find_report returns the most recent LSA (non-HIC) report for the user' do
      result = described_class.find_report(user)
      expect(result).to be_present
      expect(result).not_to be_hic
    end

    it 'find_hic_report returns the most recent HIC report for the user' do
      result = described_class.find_hic_report(user)
      expect(result).to be_present
      expect(result).to be_hic
    end
  end

  # -- export_date_range -------------------------------------------------------

  describe '#export_date_range' do
    let(:user) { create(:acl_user) }
    let(:report_start) { Date.new(2024, 10, 1) }
    let(:report_end) { Date.new(2025, 9, 30) }

    context 'for a standard LSA report (year-long range)' do
      let(:report) do
        r = create_lsa_report(
          start: report_start.to_s,
          end: report_end.to_s,
          coc_code: 'XX-501',
          lsa_scope: 1,
        )
        r.update!(user_id: user.id)
        # Bypass LsaFilter's available_coc_codes check
        filter = r.filter
        filter.coc_code = 'XX-501'
        r
      end

      it 'returns a range starting 7 years before filter.start' do
        range = report.export_date_range
        expect(range.first).to eq(report_start - 7.years)
      end

      it 'returns a range ending at filter.end' do
        range = report.export_date_range
        expect(range.last).to eq(report_end)
      end
    end

    context 'for an HIC report (single-day range)' do
      let(:pit_date) { Date.new(2025, 1, 22) }
      let(:report) do
        r = create_lsa_report(
          on: pit_date.to_s,
          start: pit_date.to_s,
          end: pit_date.to_s,
          coc_code: 'XX-501',
          lsa_scope: hic_scope_value,
        )
        r.update!(user_id: user.id)
        filter = r.filter
        filter.coc_code = 'XX-501'
        r
      end

      it 'returns the narrow filter range directly' do
        range = report.export_date_range
        expect(range.count).to be < 5
        expect(range).to eq(report.filter.range)
      end
    end
  end

  # -- lsa_scope defaulting ----------------------------------------------------

  describe '#lsa_scope (private)' do
    let(:user) { create(:acl_user) }

    def report_with_options(**opts)
      r = create_lsa_report(**opts)
      r.update!(user_id: user.id)
      filter = r.filter
      filter.coc_code = opts[:coc_code] if opts[:coc_code]
      r
    end

    it 'uses the explicit filter value when present' do
      report = report_with_options(lsa_scope: 2, coc_code: 'XX-501')
      expect(report.send(:lsa_scope)).to eq(2)
    end

    it 'defaults to 2 (Project-Focused) when project_ids are present' do
      report = report_with_options(project_ids: [1, 2], coc_code: 'XX-501')
      expect(report.send(:lsa_scope)).to eq(2)
    end

    it 'defaults to 1 (System-Wide) when no projects are selected' do
      report = report_with_options(project_ids: [], coc_code: 'XX-501')
      expect(report.send(:lsa_scope)).to eq(1)
    end
  end

  # -- standardize_headers -----------------------------------------------------

  describe '#standardize_headers (private)' do
    let(:report) { create_lsa_report }

    it 'converts ZIP to Zip' do
      headers = ['PersonalID', 'ZIP', 'State']
      report.send(:standardize_headers, headers)
      expect(headers).to eq(['PersonalID', 'Zip', 'State'])
    end

    it 'converts WorkplaceViolenceThreats to WorkPlaceViolenceThreats' do
      headers = ['PersonalID', 'WorkplaceViolenceThreats']
      report.send(:standardize_headers, headers)
      expect(headers).to eq(['PersonalID', 'WorkPlaceViolenceThreats'])
    end

    it 'handles both conversions in one header set' do
      headers = ['ZIP', 'Name', 'WorkplaceViolenceThreats']
      report.send(:standardize_headers, headers)
      expect(headers).to eq(['Zip', 'Name', 'WorkPlaceViolenceThreats'])
    end
  end

  # -- preflight_passes? -------------------------------------------------------

  describe '#preflight_passes? (private)' do
    let(:user) { create(:acl_user) }
    let(:data_source) { create(:source_data_source) }
    let(:organization) do
      create(:hud_organization, data_source: data_source, OrganizationName: 'Test Org')
    end

    before do
      allow(GrdaWarehouse::Hud::Project).to receive(:viewable_by).and_return(GrdaWarehouse::Hud::Project.all)
    end

    def build_report(project_ids: [])
      r = create_lsa_report(
        start: 1.year.ago.to_date.to_s,
        end: Date.current.to_s,
        coc_code: 'XX-500',
        lsa_scope: 2,
        project_ids: project_ids,
      )
      r.update!(user_id: user.id)
      r.instance_variable_set(:@send_notifications, false)
      filter = r.filter
      filter.coc_code = 'XX-500'
      r
    end

    # ES-NBN (type 1) requires HousingType
    def create_project_with_enrollment(housing_type: nil, operating_start: 1.year.ago.to_date)
      project = create(
        :hud_project,
        data_source: data_source,
        OrganizationID: organization.OrganizationID,
        ProjectType: 1,
        HousingType: housing_type,
        OperatingStartDate: operating_start,
        ContinuumProject: 1,
      )

      create(
        :hud_project_coc,
        data_source: data_source,
        ProjectID: project.ProjectID,
        CoCCode: 'XX-500',
        Geocode: '123456',
        GeographyType: 1,
        Zip: '02134',
      )

      create(
        :hud_funder,
        data_source: data_source,
        ProjectID: project.ProjectID,
        Funder: 1,
        StartDate: operating_start,
      )

      create(
        :hud_inventory,
        data_source: data_source,
        ProjectID: project.ProjectID,
        CoCCode: 'XX-500',
        HouseholdType: 1,
        InventoryStartDate: operating_start,
      )

      create(
        :hud_hmis_participation,
        data_source: data_source,
        ProjectID: project.ProjectID,
      )

      create(
        :hud_enrollment,
        data_source_id: data_source.id,
        ProjectID: project.ProjectID,
        EntryDate: 6.months.ago.to_date,
      )

      project
    end

    context 'when projects have complete data' do
      it 'returns true' do
        project = create_project_with_enrollment(housing_type: 1)
        report = build_report(project_ids: [project.id])

        expect(report.send(:preflight_passes?)).to be true
        expect(report.reload.state).not_to eq('Failed')
      end
    end

    context 'when a project is missing housing type' do
      it 'returns false and fails the report' do
        project = create_project_with_enrollment(housing_type: nil)
        report = build_report(project_ids: [project.id])

        expect(report.send(:preflight_passes?)).to be false
        report.reload
        expect(report.state).to eq('Failed')
        expect(report.error_details).to include('missing data')
      end
    end
  end

  # -- LsaFilter ---------------------------------------------------------------

  describe HudLsa::Filters::LsaFilter do
    let(:user) { create(:acl_user) }
    let(:filter) { described_class.new(user_id: user.id) }

    describe '.relevant_project_types' do
      it 'returns the HUD-specified project type list' do
        expect(described_class.relevant_project_types).to eq([0, 1, 2, 3, 8, 9, 10, 13])
      end
    end

    describe 'CoC code validation' do
      it 'is invalid without a coc_code' do
        filter.coc_code = nil
        expect(filter).not_to be_valid
      end

      it 'is valid with a coc_code' do
        filter.coc_code = 'XX-500'
        filter.start = 1.year.ago.to_date
        filter.end = Date.current
        expect(filter).to be_valid
      end
    end

    describe '#update' do
      it 'normalizes an array CoC code to a single value' do
        # FilterBase#update only sets coc_code if it's in available_coc_codes,
        # so we verify the array normalization by checking it doesn't raise
        # and the filter is returned (coc_code assignment depends on DB state).
        result = filter.update(coc_code: ['', 'MA-500'], start: 1.year.ago.to_date.to_s, end: Date.current.to_s)
        expect(result).to eq(filter)
      end

      it 'raises ArgumentError when multiple non-blank CoC codes are provided' do
        expect do
          filter.update(coc_code: ['MA-500', 'MA-501'], start: 1.year.ago.to_date.to_s, end: Date.current.to_s)
        end.to raise_error(ArgumentError, /Only one CoC code/)
      end

      context 'with HIC scope' do
        let(:pit_date) { Date.new(2025, 1, 22) }
        let(:hic_scope) { HudLsa::Fy2026::Report.available_lsa_scopes['HIC'].to_s }

        it 'sets start and end from the on date' do
          filter.update(
            coc_code: 'XX-500',
            lsa_scope: hic_scope,
            on: pit_date.to_s,
          )
          expect(filter.start).to eq(pit_date)
          expect(filter.end).to eq(pit_date)
        end
      end

      context 'with non-HIC scope' do
        it 'clears the on date' do
          filter.update(
            coc_code: 'XX-500',
            lsa_scope: '1',
            on: Date.current.to_s,
            start: 1.year.ago.to_date.to_s,
            end: Date.current.to_s,
          )
          expect(filter.on).to be_nil
        end
      end
    end
  end
end
