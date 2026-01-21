# frozen_string_literal: true

require 'rails_helper'
require_relative '../generators/fy2026/hopwa_caper_shared_context'

RSpec.describe HopwaCaper::DrilldownPresenter, type: :model do
  include_context 'HOPWA CAPER shared context'

  let(:tbra_funder) { hud_code(:funding_sources, 'HUD: HOPWA - Permanent Housing (facility based or TBRA)') }
  let(:project) { create_hopwa_project(funder: tbra_funder) }
  let(:report) { create_report([project]) }
  let(:client) do
    c = create_client_with_warehouse_link(first_name: 'John', last_name: 'Doe', dob: Date.new(1980, 1, 1))
    c.update!(Sex: 1)
    GrdaWarehouse::Hud::Client.where(PersonalID: c.PersonalID).update_all(Sex: 1)
    c
  end

  let(:enrollment_record) do
    create_hiv_positive_enrollment(
      client: client,
      project: project,
      entry_date: report_start_date,
      household_id: Hmis::Hud::Base.generate_uuid,
      relationship_to_ho_h: 1,
    )
    run_report(report)
    report.hopwa_caper_enrollments.first
  end

  describe '#headers' do
    it 'returns headers for enrollment records' do
      presenter = described_class.new([enrollment_record], report, user)
      headers = presenter.headers
      expect(headers).to include('personal_id' => 'HMIS Personal ID')
      expect(headers).to include('services_summary' => 'Services (Record Type: Type Provided)')
      expect(headers).to include('first_name' => 'First name')
    end
  end

  describe '#display_value' do
    let(:presenter) { described_class.new([enrollment_record], report, user, format: format) }
    let(:format) { :html }

    context 'with enrollment records' do
      it 'transforms sex code to label' do
        expect(presenter.display_value(enrollment_record, 'sex')).to eq('Male')
      end

      it 'transforms boolean values to Yes/No icons in HTML' do
        enrollment_record.update!(veteran: true)
        val = presenter.display_value(enrollment_record, 'veteran')
        expect(val).to include('icon-checkmark')
        expect(val).to include('o-color--positive')
      end

      it 'transforms boolean values to Yes/No text in Excel' do
        enrollment_record.update!(veteran: true)
        excel_presenter = described_class.new([enrollment_record], report, user, format: :excel)
        expect(excel_presenter.display_value(enrollment_record, 'veteran')).to eq('Yes')
      end

      it 'masks PII based on policy' do
        # Use existing policy classes
        allow(user).to receive(:reporting_policy_for_project).and_return(
          GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance,
        )
        expect(presenter.display_value(enrollment_record, 'first_name')).to eq('John')

        # Mock policy to deny
        allow(user).to receive(:reporting_policy_for_project).and_return(
          GrdaWarehouse::AuthPolicies::DenyPiiPolicy.instance,
        )
        expect(presenter.display_value(enrollment_record, 'first_name')).to eq('Redacted')
      end

      it 'renders arrays as semicolon-separated' do
        # Race codes for Black (3) and White (5). Sort by ID: [3, 5]
        enrollment_record.update!(races: [3, 5])
        val = presenter.display_value(enrollment_record, 'races')
        expect(val).to eq('Black, African American, or African; White')
      end

      it 'handles household_project_funders aggregation' do
        strmu_code = hud_code(:funding_sources, 'HUD: HOPWA - Short-Term Rent, Mortgage, Utility assistance')

        # Create a second enrollment for the same client in an STRMU-funded project.
        # Note: the primary 'project' (from let) is already TBRA-funded.
        strmu_project = create_hopwa_project(funder: strmu_code)
        create_hiv_positive_enrollment(
          client: client,
          project: strmu_project,
          entry_date: report_start_date,
          household_id: enrollment_record.enrollment.household_id,
        )

        # Run report for both the TBRA project and the STRMU project
        summary_report = create_report([project, strmu_project])
        run_report(summary_report)
        report_enrollment = summary_report.hopwa_caper_enrollments.find_by(enrollment_id: enrollment_record.enrollment_id)

        new_presenter = described_class.new([report_enrollment], summary_report, user)
        val = new_presenter.display_value(report_enrollment, 'household_project_funders')

        # Should include both funders, transformed to their labels:
        # project (TBRA funder) -> 'TBRA'
        # strmu_project (STRMU funder) -> 'STRMU'
        expect(val).to eq('STRMU; TBRA')
      end

      it 'handles services_summary aggregation' do
        # Use a fresh report for this complex setup
        summary_report = create_report([project])
        enrollment = create_hiv_positive_enrollment(
          client: client,
          project: project,
          entry_date: report_start_date,
          household_id: Hmis::Hud::Base.generate_uuid,
          relationship_to_ho_h: 1,
        )
        create(:hud_service, enrollment: enrollment,
                             record_type: hopwa_financial_assistance, type_provided: rental_assistance,
                             date_provided: report_start_date, data_source: data_source)

        run_report(summary_report)
        report_enrollment = summary_report.hopwa_caper_enrollments.first

        # Presenter needs to be initialized with the records from the same report
        new_presenter = described_class.new([report_enrollment], summary_report, user, format: :html)
        val = new_presenter.display_value(report_enrollment, 'services_summary')

        expect(val).to eq('HOPWA Financial Assistance: Rental assistance')
      end
    end
  end
end
