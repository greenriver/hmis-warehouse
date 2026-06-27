###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::EnrollmentBuilder do
  include_context 'hmis simulation builder setup'

  let(:date)             { Date.new(2026, 2, 1) }
  let(:project)          { create(:hmis_hud_project, data_source: data_source, ProjectType: 1) }
  let(:hoh_client)       { create(:hmis_hud_client, data_source: data_source) }
  let(:member_client)    { create(:hmis_hud_client, data_source: data_source) }
  let(:hud_household_id) { HmisSimulation::FakeIdentifier.uuid }
  let(:coc_code)         { 'XX-500' }

  def build(member_relationships: [], cohesion_probability: 1.0, population_config: {})
    described_class.new(
      project: project,
      hud_household_id: hud_household_id,
      entry_date: date,
      coc_code: coc_code,
      hoh_client: hoh_client,
      member_relationships: member_relationships,
      household_cohesion_probability: cohesion_probability,
      population_config: population_config,
      data_source: data_source,
      user_id: user_id,
      rng_seed: 42,
    ).build!
  end

  describe '#build!' do
    context 'with no household members' do
      it 'creates exactly one Enrollment (for the HoH)' do
        expect { build }.to change { Hmis::Hud::Enrollment.where(data_source: data_source).count }.by(1)
      end

      it 'sets RelationshipToHoH to 1 (self) on the HoH enrollment' do
        result = build
        expect(result[:hoh_enrollment].RelationshipToHoH).to eq(1)
      end

      it 'uses a FAKE EnrollmentID on the HoH enrollment' do
        result = build
        expect(result[:hoh_enrollment].EnrollmentID).to start_with('FAKE')
      end

      it 'sets EntryDate to the provided entry_date' do
        result = build
        expect(result[:hoh_enrollment].EntryDate).to eq(date)
      end

      it 'sets the HouseholdID on the enrollment' do
        result = build
        expect(result[:hoh_enrollment].HouseholdID).to eq(hud_household_id)
      end

      it 'links enrollment to the correct project via project_pk' do
        result = build
        expect(result[:hoh_enrollment].project_pk).to eq(project.id)
      end

      it 'returns empty member_enrollments array' do
        result = build
        expect(result[:member_enrollments]).to be_empty
      end
    end

    context 'with household members and cohesion_probability: 1.0' do
      let(:members) { [{ 'hud_client_id' => member_client.id, 'relationship_to_hoh' => 2 }] }

      it 'creates 2 enrollments (HoH + member)' do
        expect { build(member_relationships: members) }.
          to change { Hmis::Hud::Enrollment.where(data_source: data_source).count }.by(2)
      end

      it 'sets correct RelationshipToHoH (2) on the member enrollment' do
        result = build(member_relationships: members)
        expect(result[:member_enrollments].first.RelationshipToHoH).to eq(2)
      end

      it 'shares HouseholdID across HoH and member' do
        result = build(member_relationships: members)
        expect(result[:member_enrollments].first.HouseholdID).to eq(result[:hoh_enrollment].HouseholdID)
      end
    end

    context 'with cohesion_probability: 0.0 (no members included)' do
      let(:members) { [{ 'hud_client_id' => member_client.id, 'relationship_to_hoh' => 2 }] }

      it 'creates only 1 enrollment (the HoH)' do
        expect { build(member_relationships: members, cohesion_probability: 0.0) }.
          to change { Hmis::Hud::Enrollment.where(data_source: data_source).count }.by(1)
      end

      it 'returns empty member_enrollments array' do
        result = build(member_relationships: members, cohesion_probability: 0.0)
        expect(result[:member_enrollments]).to be_empty
      end
    end

    context 'HUD 3.917 Prior Living Situation fields' do
      it 'sets LivingSituation to a valid HUD code' do
        enrollment = build[:hoh_enrollment]
        valid = HudHelper.util.valid_prior_living_situations.map(&:to_s).to_set
        expect(valid).to include(enrollment.LivingSituation.to_s)
      end

      it 'draws LivingSituation from prior_living_situation distribution when configured' do
        pop_cfg = { 'prior_living_situation' => { 'distribution' => 'weighted', 'weights' => { '101' => 1.0 } } }
        enrollment = build(population_config: pop_cfg)[:hoh_enrollment]
        expect(enrollment.LivingSituation).to eq(101)
      end

      it 'sets LengthOfStay to a valid HUD code' do
        enrollment = build[:hoh_enrollment]
        valid = HudHelper.util.length_of_stays.keys
        expect(valid).to include(enrollment.LengthOfStay)
      end

      it 'sets LOSUnderThreshold derived from LengthOfStay' do
        enrollment = build[:hoh_enrollment]
        los = enrollment.LengthOfStay
        if [10, 11].include?(los)
          expect(enrollment.LOSUnderThreshold).to eq(1)
        elsif [8, 9, 99].include?(los)
          expect(enrollment.LOSUnderThreshold).to eq(99)
        else
          expect(enrollment.LOSUnderThreshold).to eq(0)
        end
      end

      it 'sets PreviousStreetESSH to 0, 1, or 99' do
        enrollment = build[:hoh_enrollment]
        expect([0, 1, 99]).to include(enrollment.PreviousStreetESSH)
      end

      it 'sets DateToStreetESSH when PreviousStreetESSH is 1' do
        # Try several seeds until we get PreviousStreetESSH = 1
        pop_cfg = { 'prior_living_situation' => { 'distribution' => 'weighted', 'weights' => { '116' => 1.0 } } }
        results = 30.times.map do |i|
          described_class.new(
            project: project, hud_household_id: HmisSimulation::FakeIdentifier.uuid,
            entry_date: date, coc_code: coc_code, hoh_client: hoh_client,
            population_config: pop_cfg, data_source: data_source,
            user_id: user_id, rng_seed: i
          ).build![:hoh_enrollment]
        end
        with_prev_street = results.select { |e| e.PreviousStreetESSH == 1 }
        next if with_prev_street.empty?

        with_prev_street.each { |e| expect(e.DateToStreetESSH).to be_present }
      end
    end

    context 'MoveInDate' do
      it 'does not set MoveInDate on PH enrollment at entry (tick_housing_move_in sets it later)' do
        psh_project = create(:hmis_hud_project, data_source: data_source, ProjectType: 3)
        enrollment = described_class.new(
          project: psh_project,
          hud_household_id: HmisSimulation::FakeIdentifier.uuid,
          entry_date: date,
          coc_code: coc_code,
          hoh_client: hoh_client,
          data_source: data_source,
          user_id: user_id,
          rng_seed: 42,
        ).build![:hoh_enrollment]
        expect(enrollment.MoveInDate).to be_nil
      end

      it 'does not set MoveInDate on non-PH enrollment' do
        enrollment = build[:hoh_enrollment]
        expect(enrollment.MoveInDate).to be_nil
      end
    end

    context 'ReferralSource' do
      it 'sets ReferralSource to a valid HUD code' do
        enrollment = build[:hoh_enrollment]
        valid = HudHelper.util.referral_sources.keys
        expect(valid).to include(enrollment.ReferralSource)
      end
    end

    context 'DateOfEngagement for Street Outreach (project_type 4)' do
      let(:so_project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 4) }

      def build_so(seed: 42)
        described_class.new(
          project: so_project,
          hud_household_id: HmisSimulation::FakeIdentifier.uuid,
          entry_date: date,
          coc_code: coc_code,
          hoh_client: hoh_client,
          data_source: data_source,
          user_id: user_id,
          rng_seed: seed,
        ).build!
      end

      it 'sets DateOfEngagement on SO enrollments' do
        enrollment = build_so[:hoh_enrollment]
        expect(enrollment.DateOfEngagement).to be_present
      end

      it 'sets DateOfEngagement on or after entry date' do
        enrollment = build_so[:hoh_enrollment]
        expect(enrollment.DateOfEngagement).to be >= date
      end

      it 'sets DateOfEngagement within 7 days of entry' do
        enrollment = build_so[:hoh_enrollment]
        expect(enrollment.DateOfEngagement).to be <= date + 7
      end

      it 'does not set DateOfEngagement for non-SO project (type 1)' do
        enrollment = build[:hoh_enrollment]
        expect(enrollment.DateOfEngagement).to be_nil
      end

      # Regression: bare rand(0..7) produces a different value on every call.
      # After fix, DateOfEngagement uses Random.new(@rng_seed + offset) and is stable.
      it 'produces the same DateOfEngagement for the same rng_seed (determinism)' do
        date1 = build_so(seed: 99)[:hoh_enrollment].DateOfEngagement
        date2 = build_so(seed: 99)[:hoh_enrollment].DateOfEngagement
        expect(date1).to eq(date2)
      end
    end
  end
end
