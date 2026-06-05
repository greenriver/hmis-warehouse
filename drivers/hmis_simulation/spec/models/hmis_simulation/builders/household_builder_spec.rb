###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::HouseholdBuilder do
  let!(:data_source) { create(:hmis_data_source) }
  let(:user_id) do
    User.setup_system_user
    Hmis::Hud::User.system_user(data_source_id: data_source.id).user_id
  end
  let(:date)  { Date.new(2026, 1, 15) }
  let(:seed)  { 99 }

  let(:adult_only_template) do
    {
      'hoh' => {
        'age' => { 'distribution' => 'uniform', 'min' => 25, 'max' => 55 },
        'gender' => { 'woman' => 0.5, 'man' => 0.5 },
        'veteran_probability' => 0.0,
        'race' => { 'white' => 1.0 },
      },
    }
  end

  let(:adult_and_child_template) do
    {
      'hoh' => {
        'age' => { 'distribution' => 'uniform', 'min' => 25, 'max' => 40 },
        'gender' => { 'woman' => 1.0 },
        'veteran_probability' => 0.0,
        'race' => { 'white' => 1.0 },
      },
      'members' => [
        {
          'role' => 'child',
          'count' => { 'distribution' => 'constant', 'value' => 2 },
          'age' => { 'distribution' => 'uniform', 'min' => 2, 'max' => 10 },
          'relationship' => 2,
        },
      ],
    }
  end

  def build(template, template_name: 'test_template')
    described_class.new(
      household_template: template,
      household_template_name: template_name,
      data_quality_config: {},
      data_source: data_source,
      user_id: user_id,
      date: date,
      seed: seed,
      context_prefix: 'test:hh:0',
    ).build!
  end

  describe '#build!' do
    context 'with adult_only template (no members)' do
      it 'creates exactly one Client (the HoH)' do
        expect { build(adult_only_template) }.
          to change { Hmis::Hud::Client.where(data_source: data_source).count }.by(1)
      end

      it 'creates an hmis_simulation_household_groups record with no members' do
        result = build(adult_only_template)
        group = HmisSimulation::HouseholdGroup.find(result[:household_group_id])
        expect(group.member_client_ids).to be_empty
      end

      it 'returns a hud_household_id that is a FAKE UUID' do
        result = build(adult_only_template)
        expect(result[:hud_household_id]).to start_with('FAKE')
        expect(result[:hud_household_id].length).to eq(32)
      end

      it 'returns an empty member_relationships array' do
        result = build(adult_only_template)
        expect(result[:member_relationships]).to be_empty
      end
    end

    context 'with adult_and_child template (count: constant 2 children)' do
      it 'creates 3 Client records (HoH + 2 children)' do
        expect { build(adult_and_child_template) }.
          to change { Hmis::Hud::Client.where(data_source: data_source).count }.by(3)
      end

      it 'creates an hmis_simulation_household_groups record with 2 member entries' do
        result = build(adult_and_child_template)
        group = HmisSimulation::HouseholdGroup.find(result[:household_group_id])
        expect(group.member_client_ids.length).to eq(2)
      end

      it 'stores relationship_to_hoh for each member' do
        result = build(adult_and_child_template)
        group = HmisSimulation::HouseholdGroup.find(result[:household_group_id])
        relationships = group.member_client_ids.map { |m| m['relationship_to_hoh'] }
        expect(relationships).to all(eq(2))
      end

      it 'returns member_relationships with hud_client_id and relationship_to_hoh' do
        result = build(adult_and_child_template)
        expect(result[:member_relationships].length).to eq(2)
        result[:member_relationships].each do |m|
          expect(m).to include('hud_client_id', 'relationship_to_hoh')
          expect(m['relationship_to_hoh']).to eq(2)
        end
      end

      it 'gives children ages within the configured range' do
        result = build(adult_and_child_template)
        member_ids = result[:member_relationships].map { |m| m['hud_client_id'] }
        members = Hmis::Hud::Client.where(id: member_ids)
        members.each do |m|
          age = ((date - m.DOB) / 365.25).to_i
          expect(age).to be_between(2, 10)
        end
      end
    end

    it 'links household_group to the correct data_source' do
      result = build(adult_only_template)
      group = HmisSimulation::HouseholdGroup.find(result[:household_group_id])
      expect(group.data_source_id).to eq(data_source.id)
      expect(group.hoh_client_id).to eq(result[:hoh_id])
    end

    it 'returns the hoh_id matching the created HoH Client record id' do
      result = build(adult_only_template)
      client = Hmis::Hud::Client.find(result[:hoh_id])
      expect(client.PersonalID).to start_with('FAKE')
    end
  end
end
