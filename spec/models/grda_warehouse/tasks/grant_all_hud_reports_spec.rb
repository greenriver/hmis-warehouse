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
  # permission_context is nullable; User#using_acls? treats nil as legacy.
  let(:null_context_hud_user) { create(:user, permission_context: nil) }
  let(:hud_role_collection) { create(:collection) }
  let!(:project) { create(:hud_project) }

  before do
    # A project in the HUD role's collection proves the grant does not make it reportable.
    hud_role_collection.set_viewables(projects: [project.id])
    setup_access_control(acl_hud_user, hud_role, hud_role_collection)
    # A stale legacy role on an ACL user must not route them through the legacy grant.
    acl_hud_user.legacy_roles << hud_role
    setup_access_control(acl_plain_user, plain_role, create(:collection))
    legacy_hud_user.legacy_roles << hud_role
    legacy_plain_user.legacy_roles << plain_role
    null_context_hud_user.legacy_roles << hud_role
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
    expect(AccessGroup.system_group(:hud_reports).users).to contain_exactly(legacy_hud_user, null_context_hud_user)
  end

  it 'lets a legacy HUD user see every HUD definition' do
    expect(definitions.viewable_by(legacy_hud_user.reload).pluck(:url)).to match_array(definitions.hud.pluck(:url))
  end

  it 'is idempotent' do
    expect { described_class.new.run! }.not_to change(AccessControl, :count)
  end

  it 'does not re-grant access an admin has since removed' do
    AccessControl.where(role_id: described_class.viewer_role.id).destroy_all

    described_class.new.run!

    expect(definitions.viewable_by(acl_hud_user.reload)).to be_empty
  end

  it 'does not grant a role that gains a HUD flag after the one-time run' do
    late_user = create(:acl_user)
    setup_access_control(late_user, create(:role, can_view_all_hud_reports: true), create(:collection))

    described_class.new.run!

    expect(definitions.viewable_by(late_user.reload)).to be_empty
  end
end

RSpec.describe GrdaWarehouse::Tasks::GrantAllHudReports, 'when the grant fails partway' do
  let(:hud_role) { create(:role, can_view_own_hud_reports: true) }
  let(:acl_hud_user) { create(:acl_user) }
  let(:legacy_hud_user) { create(:user) }

  before do
    setup_access_control(acl_hud_user, hud_role, create(:collection))
    legacy_hud_user.legacy_roles << hud_role
    failing_task = described_class.new
    allow(failing_task).to receive(:grant_legacy_users).and_raise(ActiveRecord::StatementInvalid)

    expect { failing_task.run! }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'rolls back the ACL grant and the viewer role' do
    expect(described_class.viewer_roles).not_to exist
    expect(AccessControl.where(user_group_id: acl_hud_user.user_groups.select(:id)).pluck(:role_id)).to eq([hud_role.id])
  end

  it 'grants the legacy users on the next run' do
    described_class.new.run!

    expect(AccessGroup.system_group(:hud_reports).users).to contain_exactly(legacy_hud_user)
  end
end
