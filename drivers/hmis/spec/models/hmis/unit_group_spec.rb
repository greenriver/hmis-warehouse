# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::UnitGroup, type: :model do
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
    let(:builder_instance) { instance_double(Hmis::Ce::Match::CandidatePoolBuilder, perform: true) }

    before do
      allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:new).and_return(builder_instance)
    end

    it 'calls CandidatePoolBuilder after creation with its own id' do
      new_unit_group = create(:hmis_unit_group, project: project)
      expect(builder_instance).to have_received(:perform).with(unit_group_ids: [new_unit_group.id])
    end
  end
end
