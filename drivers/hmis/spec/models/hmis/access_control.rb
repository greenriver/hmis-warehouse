require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::AccessControl, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  # include_context 'hmis base setup'

  let(:ds1) { create :hmis_data_source }
  let(:user) { create(:user) }
  let(:hmis_user) { user.related_hmis_user(ds1) }
  let(:u1) { Hmis::Hud::User.from_user(hmis_user) }
  let(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let(:o2) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let(:p3) { create :hmis_hud_project, data_source: ds1, organization: o2, user: u1 }
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }
  let(:role) { create :hmis_role }
  let(:edit_access_group) do
    group = create :edit_access_group
    group.access_controls.create(role: role)
    group
  end
  let(:pag1) do
    pag = GrdaWarehouse::ProjectAccessGroup.create!(name: 'PAG 1')
    pag.projects = [p1.as_warehouse, p3.as_warehouse]
    pag.save!
    pag
  end

  describe 'entity ownership tests' do
    it 'should apply correctly when attached directly to a project' do
      assign_viewable(edit_access_group, p1, hmis_user)
      expect(hmis_user.can_view_full_ssn_for?(p1)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p2)).to eq(false)
      expect(hmis_user.can_view_full_ssn_for?(p3)).to eq(false)
    end

    it 'should apply correctly when attached to a project\'s organization' do
      assign_viewable(edit_access_group, o1, hmis_user)
      expect(hmis_user.can_view_full_ssn_for?(p1)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p2)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p3)).to eq(false)
    end

    it 'should apply correctly when attached to a data source' do
      assign_viewable(edit_access_group, ds1, hmis_user)
      expect(hmis_user.can_view_full_ssn_for?(p1)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p2)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p3)).to eq(true)
    end

    it 'should apply correctly when attached to a project access group' do
      assign_viewable(edit_access_group, pag1, hmis_user)
      expect(hmis_user.can_view_full_ssn_for?(p1)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p2)).to eq(false)
      expect(hmis_user.can_view_full_ssn_for?(p3)).to eq(true)
    end
  end

  describe 'specific permissions tets' do
    it 'should have correct permissions based on the role' do
      assign_viewable(edit_access_group, p1, hmis_user)
      role.update(can_view_full_ssn: false)
      expect(hmis_user.can_view_clients_for?(p1)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p1)).to eq(false)
    end

    it 'should handle roles attached to other related entities correctly' do
      assign_viewable(edit_access_group, p1, hmis_user)
      role.update(can_view_full_ssn: false)

      group2 = create :edit_access_group
      group2.access_controls.create(role: create(:hmis_role))
      assign_viewable(group2, o1, hmis_user)

      expect(hmis_user.can_view_clients_for?(p1)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p1)).to eq(true)
      expect(hmis_user.can_view_clients_for?(p2)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p2)).to eq(true)
    end
  end
end
