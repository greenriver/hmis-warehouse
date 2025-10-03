# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::UnitGroup, type: :model do
  include_context 'hmis base setup'
  let!(:project) { create(:hmis_hud_project) }
  let!(:unit_group) { create(:hmis_unit_group, project: project) }

  describe 'validations' do
    it 'prevents the project from being changed' do
      new_project = create(:hmis_hud_project)
      unit_group.project = new_project
      expect(unit_group).not_to be_valid
      expect(unit_group.errors[:project]).to include('cannot be changed')
    end
  end

  describe 'callbacks' do
    before do
      allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    end

    it 'calls CandidatePoolBuilder after creation with its own id' do
      new_unit_group = create(:hmis_unit_group, project: project)
      expect(Hmis::Ce::Match::CandidatePoolBuilder).to have_received(:call).with(unit_group_ids: [new_unit_group.id])
    end
  end

  describe 'paranoia' do
    let(:build_record) { -> { create(:hmis_unit_group, project: create(:hmis_hud_project)) } }

    it_behaves_like 'paranoid model'
  end

  describe 'paper trail' do
    let(:build_record) { -> { create(:hmis_unit_group, project: create(:hmis_hud_project)) } }
    let(:update_attributes_for_versioning) { ->(record) { record.update!(name: "Updated #{record.name}") } }

    it_behaves_like 'versioned model'
  end
end
