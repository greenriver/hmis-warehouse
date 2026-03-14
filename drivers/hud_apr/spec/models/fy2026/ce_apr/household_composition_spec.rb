###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Regression tests for CE APR assessment-date household composition.
#
# The CE APR spec requires household composition to be determined as of the latest
# CE assessment date, not across the full report period. Specifically:
#   - household_type, household_members, other_clients_over_25, and parenting_youth
#     must reflect only those members whose enrollment spanned the assessment date.
#   - Age is still calculated using the standard HUD rule (max of project start / report start).
#
# These tests guard against a regression in AprClientBuilder#map_ce_attributes where
# those fields would otherwise be copied from the full-period HouseholdContext values.

require 'rails_helper'
require_relative './shared_context'

RSpec.describe 'CE APR FY2026 assessment-date household composition', type: :model, exclude_fixpoints: true do
  include_context 'HUD CE APR FY2026 setup'

  let(:report_start)    { Date.new(2025, 10, 1) }
  let(:assessment_date) { Date.new(2026, 3, 1) }

  # A date before assessment_date that a household member can exit on, verifying
  # that they are excluded from the assessment-date composition snapshot.
  let(:pre_assessment_exit) { Date.new(2026, 1, 15) }

  def create_ce_project
    project = create_project(project_type: 14) # CE project type
    create(
      :hud_ce_participation,
      ProjectID: project.project_id,
      data_source: data_source,
      CEParticipationStatusStartDate: report_start - 1.year,
      CEParticipationStatusEndDate: nil,
      AccessPoint: 1,
    )
    project
  end

  def add_assessment(enrollment:, date: assessment_date)
    create(
      :hud_assessment,
      EnrollmentID: enrollment.EnrollmentID,
      PersonalID: enrollment.PersonalID,
      data_source: data_source,
      AssessmentDate: date,
      AssessmentType: 1,
      AssessmentLevel: 1,
      PrioritizationStatus: 1,
    )
  end

  def apr_client_for(report, source_client)
    HudApr::Fy2020::AprClient.find_by(
      report_instance_id: report.id,
      client_id: source_client.id,
    )
  end

  # --------------------------------------------------------------------------
  # household_type and parenting_youth
  # A youth HoH with a child: child present vs. absent at assessment date.
  # --------------------------------------------------------------------------
  describe 'household_type and parenting_youth' do
    let(:hoh_dob)   { Date.new(2004, 1, 1) }  # age ~21 at report start
    let(:child_dob) { Date.new(2020, 1, 1) }  # minor child

    before do
      @project      = create_ce_project
      @household_id = Hmis::Hud::Base.generate_uuid

      @youth_hoh = create_client_with_warehouse_link(dob: hoh_dob)
      hoh_enrollment = create_enrollment(
        client: @youth_hoh,
        project: @project,
        entry_date: Date.new(2025, 11, 1),
        relationship_to_ho_h: 1,
        household_id: @household_id,
      )
      add_assessment(enrollment: hoh_enrollment)

      child = create_client_with_warehouse_link(dob: child_dob)
      create_enrollment(
        client: child,
        project: @project,
        entry_date: Date.new(2025, 11, 1),
        exit_date: child_exit_date,
        relationship_to_ho_h: 2,
        household_id: @household_id,
      )

      @report = setup_ce_apr_report(@project.id)
      run_ce_apr_report(@report)
    end

    context 'when the child exits before the assessment date' do
      let(:child_exit_date) { pre_assessment_exit }

      it 'classifies household as adults_only' do
        expect(apr_client_for(@report, @youth_hoh).household_type).to eq('adults_only')
      end

      it 'does not flag the HoH as parenting_youth' do
        expect(apr_client_for(@report, @youth_hoh).parenting_youth).to be false
      end
    end

    context 'when the child is still present at the assessment date' do
      let(:child_exit_date) { nil }

      it 'classifies household as adults_and_children' do
        expect(apr_client_for(@report, @youth_hoh).household_type).to eq('adults_and_children')
      end

      it 'flags the HoH as parenting_youth' do
        expect(apr_client_for(@report, @youth_hoh).parenting_youth).to be true
      end
    end
  end

  # --------------------------------------------------------------------------
  # other_clients_over_25
  # A youth HoH (18-24) sharing a household with an adult 25+:
  # adult present vs. absent at assessment date.
  # --------------------------------------------------------------------------
  describe 'other_clients_over_25' do
    let(:hoh_dob)   { Date.new(2004, 1, 1) }  # age ~21 at report start
    let(:adult_dob) { Date.new(1990, 1, 1) }  # age ~35 at report start

    before do
      @project      = create_ce_project
      @household_id = Hmis::Hud::Base.generate_uuid

      @youth_hoh = create_client_with_warehouse_link(dob: hoh_dob)
      hoh_enrollment = create_enrollment(
        client: @youth_hoh,
        project: @project,
        entry_date: Date.new(2025, 11, 1),
        relationship_to_ho_h: 1,
        household_id: @household_id,
      )
      add_assessment(enrollment: hoh_enrollment)

      adult = create_client_with_warehouse_link(dob: adult_dob)
      create_enrollment(
        client: adult,
        project: @project,
        entry_date: Date.new(2025, 11, 1),
        exit_date: adult_exit_date,
        relationship_to_ho_h: 3, # other household member
        household_id: @household_id,
      )

      @report = setup_ce_apr_report(@project.id)
      run_ce_apr_report(@report)
    end

    context 'when the adult over 25 exits before the assessment date' do
      let(:adult_exit_date) { pre_assessment_exit }

      it 'does not set other_clients_over_25' do
        expect(apr_client_for(@report, @youth_hoh).other_clients_over_25).to be false
      end
    end

    context 'when the adult over 25 is present at the assessment date' do
      let(:adult_exit_date) { nil }

      it 'sets other_clients_over_25' do
        expect(apr_client_for(@report, @youth_hoh).other_clients_over_25).to be true
      end
    end
  end
end
