###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::EnrollmentBuilder do
  let!(:data_source) { create(:hmis_data_source) }
  let(:user_id) do
    User.setup_system_user
    Hmis::Hud::User.system_user(data_source_id: data_source.id).user_id
  end
  let(:date) { Date.new(2026, 2, 1) }
  let(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 1) }
  let(:hoh_client) { create(:hmis_hud_client, data_source: data_source) }
  let(:member_client) { create(:hmis_hud_client, data_source: data_source) }
  let(:hud_household_id) { HmisSimulation::FakeIdentifier.uuid }
  let(:coc_code) { 'XX-500' }

  def build(member_relationships: [], cohesion_probability: 1.0)
    described_class.new(
      project: project,
      hud_household_id: hud_household_id,
      entry_date: date,
      coc_code: coc_code,
      hoh_client: hoh_client,
      member_relationships: member_relationships,
      household_cohesion_probability: cohesion_probability,
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
  end
end
