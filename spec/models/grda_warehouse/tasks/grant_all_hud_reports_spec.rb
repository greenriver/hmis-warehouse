###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::GrantAllHudReports do
  let(:definitions) { GrdaWarehouse::WarehouseReports::ReportDefinition }
  let(:hud_role) { create(:role, can_view_own_hud_reports: true) }
  let(:plain_role) { create(:role, can_view_assigned_reports: true) }
  let(:acl_hud_user) { create(:acl_user) }
  let(:acl_plain_user) { create(:acl_user) }
  let(:legacy_hud_user) { create(:user) }
  let(:legacy_plain_user) { create(:user) }
  let(:hud_role_collection) { create(:collection) }
  let!(:project) { create(:hud_project) }

  before do
    # A project in the HUD role's collection proves the grant does not make it reportable.
    hud_role_collection.set_viewables(projects: [project.id])
    setup_access_control(acl_hud_user, hud_role, hud_role_collection)
    setup_access_control(acl_plain_user, plain_role, create(:collection))
    legacy_hud_user.legacy_roles << hud_role
    legacy_plain_user.legacy_roles << plain_role
    described_class.new.run!
  end

  it 'lets ACL users with a HUD flag see every HUD definition and grants nothing to others' do
    urls = definitions.viewable_by(acl_hud_user.reload).pluck(:url)

    expect(urls).to match_array(definitions.hud.pluck(:url))
    expect(definitions.viewable_by(acl_plain_user.reload)).to be_empty
  end

  it 'does not change any existing role flags' do
    expect(hud_role.reload.can_view_assigned_reports).to be false
  end

  it 'does not widen the reportable project set for the HUD role' do
    expect(GrdaWarehouse::Hud::Project.viewable_by(acl_hud_user.reload, permission: :can_view_assigned_reports)).to be_empty
  end

  it 'adds legacy HUD users, and only them, to the All HUD Reports group' do
    expect(AccessGroup.system_group(:hud_reports).users).to contain_exactly(legacy_hud_user)
  end

  it 'lets a legacy HUD user see every HUD definition' do
    expect(definitions.viewable_by(legacy_hud_user.reload).pluck(:url)).to match_array(definitions.hud.pluck(:url))
  end

  it 'is idempotent' do
    expect { described_class.new.run! }.not_to change(AccessControl, :count)
  end
end
