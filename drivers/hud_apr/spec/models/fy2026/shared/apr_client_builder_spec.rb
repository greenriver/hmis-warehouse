# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../../spec/shared_contexts/hud_enrollment_builders'

RSpec.describe HudApr::Generators::Shared::Fy2026::AprClientBuilder, type: :model do
  include_context 'HUD enrollment builders'

  let(:report) do
    create(
      :hud_reports_report_instance,
      start_date: '2024-01-01',
      end_date: '2024-12-31',
      coc_codes: ['MA-500'],
    )
  end

  let!(:project) { create_project(project_type: 1, coc_code: 'MA-500') } # ES-NBN

  # Creates a source client, HUD enrollment, and rebuilds service history.
  # Returns [source_client, dest_client, hud_enrollment, she]
  def setup_enrollment(proj, entry_date: '2024-01-15', exit_date: nil, destination: nil)
    source_client = create_client_with_warehouse_link(dob: 35.years.ago)
    hud_enrollment = create_enrollment(
      client: source_client,
      project: proj,
      entry_date: entry_date,
      exit_date: exit_date,
      destination: destination,
      relationship_to_ho_h: 1,
    )
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(hud_enrollment.id).rebuild_service_history!
    she = GrdaWarehouse::ServiceHistoryEnrollment.find_by(enrollment_group_id: hud_enrollment.EnrollmentID)
    [source_client, source_client.destination_client, hud_enrollment, she]
  end

  # Builds a HouseholdContext record for a given SHE with sensible defaults.
  def build_context(she, source_client, dest_client, hud_enrollment, **opts)
    create(
      :hud_reports_household_context,
      report_instance: report,
      service_history_enrollment: she,
      household_id: hud_enrollment.HouseholdID,
      is_hoh: true,
      hoh_personal_id: source_client.PersonalID,
      hoh_service_history_enrollment_id: she.id,
      hoh_entry_date: she.first_date_in_program,
      age: 35,
      relationship_to_hoh: 1,
      household_type: 'adults_only',
      inherited_chronic_status: false,
      non_youth_household: true,
      is_parenting_youth: false,
      source_client_id: source_client.id,
      destination_client_id: dest_client.id,
      **opts,
    )
  end

  def invoke(dest_client:, she:, ctx:, needs_ce_assessments: false)
    households = { [ctx.household_id, ctx.data_source_id] => [ctx.to_legacy_member_hash] }
    described_class.build(
      report: report,
      client: dest_client,
      enrollments: [she],
      context_map: { she.id => ctx },
      hoh_enrollment_map: {},
      needs_ce_assessments: needs_ce_assessments,
      households: households,
    )
  end

  # ---------------------------------------------------------------------------
  # resolve_and_build – early exit paths
  # ---------------------------------------------------------------------------
  describe '#resolve_and_build' do
    it 'returns success: false when no enrollments are provided' do
      result = described_class.build(
        report: report,
        client: double('client'),
        enrollments: [],
        context_map: {},
        hoh_enrollment_map: {},
        needs_ce_assessments: false,
        households: {},
      )
      expect(result).to eq({ success: false })
    end

    it 'returns success: false when no context exists for the enrollment (unexpected internal state)' do
      _, dest_client, _, she = setup_enrollment(project)

      result = described_class.build(
        report: report,
        client: dest_client,
        enrollments: [she],
        context_map: {},
        hoh_enrollment_map: {},
        needs_ce_assessments: false,
        households: {},
      )
      expect(result).to eq({ success: false })
    end

    context 'when the enrollment CoC is not in the report CoC list' do
      let!(:other_project) { create_project(project_type: 1, coc_code: 'XX-999') }

      it 'returns success: false' do
        source_client, dest_client, hud_enrollment, she = setup_enrollment(other_project)
        ctx = build_context(she, source_client, dest_client, hud_enrollment)

        result = described_class.build(
          report: report,
          client: dest_client,
          enrollments: [she],
          context_map: { she.id => ctx },
          hoh_enrollment_map: {},
          needs_ce_assessments: false,
          households: {},
        )
        expect(result).to eq({ success: false })
      end
    end

    context 'with a valid enrollment in the report CoC' do
      it 'returns success: true with correct structural keys' do
        source_client, dest_client, hud_enrollment, she = setup_enrollment(project)
        ctx = build_context(she, source_client, dest_client, hud_enrollment)

        result = invoke(dest_client: dest_client, she: she, ctx: ctx)

        expect(result[:success]).to be true
        expect(result[:source_client_id]).to eq(source_client.id)
        expect(result[:enrollment_id]).to eq(hud_enrollment.id)
      end

      it 'returns attributes with correct enrollment CoC, age, and HoH flag' do
        source_client, dest_client, hud_enrollment, she = setup_enrollment(project)
        ctx = build_context(she, source_client, dest_client, hud_enrollment)

        attrs = invoke(dest_client: dest_client, she: she, ctx: ctx)[:attributes]

        expect(attrs[:enrollment_coc]).to eq('MA-500')
        expect(attrs[:age]).to eq(35)
        expect(attrs[:head_of_household]).to be true
        expect(attrs[:household_type]).to eq('adults_only')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # DOB quality mapping (apr_client_dob_quality)
  # ---------------------------------------------------------------------------
  describe 'dob_quality attribute' do
    it 'returns DOBDataQuality when DOB is present with quality 1' do
      source_client, dest_client, hud_enrollment, she = setup_enrollment(project)
      # create_client_with_warehouse_link sets dob_data_quality: 1 automatically when DOB present
      ctx = build_context(she, source_client, dest_client, hud_enrollment)

      attrs = invoke(dest_client: dest_client, she: she, ctx: ctx)[:attributes]
      expect(attrs[:dob_quality]).to eq(1)
    end

    it 'returns DOBDataQuality when DOB is blank with quality 9 (DK/R)' do
      source_client, dest_client, hud_enrollment, she = setup_enrollment(project)
      source_client.update!(DOB: nil, DOBDataQuality: 9)
      ctx = build_context(she, source_client, dest_client, hud_enrollment)

      attrs = invoke(dest_client: dest_client, she: she, ctx: ctx)[:attributes]
      expect(attrs[:dob_quality]).to eq(9)
    end

    it 'returns 99 for an invalid DOB/quality combination (DOB blank, quality 1)' do
      source_client, dest_client, hud_enrollment, she = setup_enrollment(project)
      source_client.update!(DOB: nil, DOBDataQuality: 1)
      ctx = build_context(she, source_client, dest_client, hud_enrollment)

      attrs = invoke(dest_client: dest_client, she: she, ctx: ctx)[:attributes]
      expect(attrs[:dob_quality]).to eq(99)
    end
  end

  # ---------------------------------------------------------------------------
  # Destination override logic
  # ---------------------------------------------------------------------------
  describe 'destination attribute' do
    it 'overrides destination 435 to 99 when no DestinationSubsidyType is recorded' do
      source_client, dest_client, hud_enrollment, she = setup_enrollment(project, exit_date: '2024-06-30', destination: 435)
      ctx = build_context(she, source_client, dest_client, hud_enrollment)

      attrs = invoke(dest_client: dest_client, she: she, ctx: ctx)[:attributes]
      expect(attrs[:destination]).to eq(99)
    end

    it 'overrides an unrecognized destination code to 99' do
      source_client, dest_client, hud_enrollment, she = setup_enrollment(project, exit_date: '2024-06-30', destination: 999)
      ctx = build_context(she, source_client, dest_client, hud_enrollment)

      attrs = invoke(dest_client: dest_client, she: she, ctx: ctx)[:attributes]
      expect(attrs[:destination]).to eq(99)
    end

    it 'keeps a valid FY2026 destination code unchanged' do
      # 410 = "Rental by client, no ongoing housing subsidy" — valid in 2026 spec
      source_client, dest_client, hud_enrollment, she = setup_enrollment(project, exit_date: '2024-06-30', destination: 410)
      ctx = build_context(she, source_client, dest_client, hud_enrollment)

      attrs = invoke(dest_client: dest_client, she: she, ctx: ctx)[:attributes]
      expect(attrs[:destination]).to eq(410)
    end
  end
end
