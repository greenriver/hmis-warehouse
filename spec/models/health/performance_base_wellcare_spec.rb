###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Health::PerformanceBase well-care visit query', type: :model do
  WELLCARE_ENV_KEY = 'WELLCARE_USE_UNION_QUERY'

  def with_env(key, value)
    original = ENV[key]
    ENV[key] = value
    yield
  ensure
    ENV[key] = original
  end

  def create_medical_claim(patient:, claim_number:, dx_1: nil, dx_2: nil, procedure_code: nil, service_start_date:, service_end_date:)
    ClaimsReporting::MedicalClaim.create!(
      member_id: patient.medicaid_id,
      claim_number: claim_number,
      line_number: '1',
      icd_version: '10',
      dx_1: dx_1,
      dx_2: dx_2,
      procedure_code: procedure_code,
      service_start_date: service_start_date,
      service_end_date: service_end_date,
      claim_status: 'P',
    )
  end

  it 'returns many patient ids across multiple well-care dx patterns and matches between legacy and union paths' do
    cc = create(:user)
    team = create(:coordination_team, team_coordinator: cc, name: 'Wellcare Team')
    create(:user_care_coordinator, coordination_team: team, user: cc)

    range = (Date.current.beginning_of_month..Date.current.end_of_month)
    anchor = [range.last, Date.current.end_of_month].min
    service_date = (anchor - 6.months).to_date

    dx_codes = [
      'Z00',
      'Z000',
      'Z001',
      'Z005',
      'Z008',
      'Z020',
      'Z021',
      'Z026',
      'Z0271',
      'Z0292',
      'Z761',
      'Z762',
    ]

    matching_patients = dx_codes.each_with_index.map do |dx, idx|
      patient = create(:patient, care_coordinator: cc)
      patient.update!(medicaid_id: patient.patient_referral.medicaid_id)
      patient.patient_referral.update!(
        enrollment_start_date: Date.current - 60.days,
        disenrollment_date: nil,
        current: true,
        contributing: true,
      )

      # Alternate between dx_1 and dx_2 to ensure we exercise the OR across columns.
      if idx.even?
        create_medical_claim(
          patient: patient,
          claim_number: "DX#{idx}",
          dx_1: dx,
          service_start_date: service_date,
          service_end_date: service_date,
        )
      else
        create_medical_claim(
          patient: patient,
          claim_number: "DX#{idx}",
          dx_2: dx,
          service_start_date: service_date,
          service_end_date: service_date,
        )
      end

      patient
    end

    # Procedure-code-only match
    proc_patient = create(:patient, care_coordinator: cc)
    proc_patient.update!(medicaid_id: proc_patient.patient_referral.medicaid_id)
    proc_patient.patient_referral.update!(
      enrollment_start_date: Date.current - 60.days,
      disenrollment_date: nil,
      current: true,
      contributing: true,
    )
    create_medical_claim(
      patient: proc_patient,
      claim_number: 'PROC',
      procedure_code: 'G0438',
      service_start_date: service_date,
      service_end_date: service_date,
    )

    # Non-matching claim (control)
    control = create(:patient, care_coordinator: cc)
    control.update!(medicaid_id: control.patient_referral.medicaid_id)
    control.patient_referral.update!(
      enrollment_start_date: Date.current - 60.days,
      disenrollment_date: nil,
      current: true,
      contributing: true,
    )
    create_medical_claim(
      patient: control,
      claim_number: 'NOPE',
      dx_1: 'A00',
      procedure_code: '99999',
      service_start_date: service_date,
      service_end_date: service_date,
    )

    legacy_ids = with_env(WELLCARE_ENV_KEY, nil) do
      report = Health::TeamPerformance.new(range: range, team_scope: Health::CoordinationTeam.where(id: team.id))
      report.with_required_wellcare_visit
    end

    union_ids = with_env(WELLCARE_ENV_KEY, '1') do
      report = Health::TeamPerformance.new(range: range, team_scope: Health::CoordinationTeam.where(id: team.id))
      report.with_required_wellcare_visit
    end

    expected_ids = (matching_patients + [proc_patient]).map(&:id)

    aggregate_failures 'well-care ids' do
      expect(legacy_ids).to match_array(expected_ids)
      expect(union_ids).to match_array(expected_ids)
      expect(legacy_ids.size).to be > 10
      expect(union_ids.size).to be > 10
      expect(legacy_ids).not_to include(control.id)
      expect(union_ids).not_to include(control.id)
    end
  end
end
