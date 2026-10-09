###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::HouseholdMembership do
  let!(:destination_data_source) { create :destination_data_source }
  let!(:hmis_data_source) { create :hmis_data_source }
  let(:project) { create :hmis_hud_project, data_source: hmis_data_source }
  let(:hoh) { create :hmis_hud_client_with_warehouse_client, data_source: hmis_data_source }
  let(:member) { create :hmis_hud_client_with_warehouse_client, data_source: hmis_data_source }
  let(:bystander) { create :hmis_hud_client_with_warehouse_client, data_source: hmis_data_source }
  let!(:hoh_enrollment) { create :hmis_hud_enrollment, data_source: hmis_data_source, client: hoh, project: project, household_id: 'HH1', relationship_to_ho_h: 1 }
  let!(:member_enrollment) { create :hmis_hud_enrollment, data_source: hmis_data_source, client: member, project: project, household_id: 'HH1', relationship_to_ho_h: 2 }
  let!(:bystander_enrollment) { create :hmis_hud_enrollment, data_source: hmis_data_source, client: bystander, project: project, household_id: 'HH2', relationship_to_ho_h: 1 }

  def exit_member
    create :hmis_hud_exit, data_source: hmis_data_source, enrollment: member_enrollment, client: member
  end

  describe '.open_member_destination_ids' do
    it 'returns the open members of the given households' do
      expect(described_class.open_member_destination_ids([[hmis_data_source.id, 'HH1']])).
        to contain_exactly(hoh.destination_client.id, member.destination_client.id)
    end

    it 'excludes members who exited' do
      exit_member
      expect(described_class.open_member_destination_ids([[hmis_data_source.id, 'HH1']])).to contain_exactly(hoh.destination_client.id)
    end

    it 'scopes HouseholdIDs by data source' do
      other_data_source = create :hmis_data_source
      expect(described_class.open_member_destination_ids([[other_data_source.id, 'HH1']])).to be_empty
    end

    it 'returns nothing for no households' do
      expect(described_class.open_member_destination_ids([])).to be_empty
    end
  end

  describe '.household_member_destination_ids' do
    it 'returns the open members of the open households the given clients belong to' do
      expect(described_class.household_member_destination_ids([hoh.destination_client.id])).
        to contain_exactly(hoh.destination_client.id, member.destination_client.id)
    end

    it 'does not reach the old household of a client who exited' do
      exit_member
      expect(described_class.household_member_destination_ids([member.destination_client.id])).to be_empty
    end
  end
end
