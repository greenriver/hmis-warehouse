###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HopwaCaper::Tasks::GrantExistingAccess do
  let(:definitions) { GrdaWarehouse::WarehouseReports::ReportDefinition }
  let(:hopwa_url) { definitions.hud_url(:hopwa_capers) }
  let(:hopwa_definition) { definitions.find_by!(url: hopwa_url) }
  let(:viewer_role) { create(:role, can_view_assigned_reports: true) }
  let(:user_group) { create(:user_group) }
  let(:acl_user) { create(:acl_user) }
  let(:late_acl_user) { create(:acl_user) }
  let(:outsider) { create(:acl_user) }
  let(:legacy_user) { create(:user) }
  let(:legacy_outsider) { create(:user) }
  let(:fy2026_title) { HopwaCaper::Generators::Fy2026::Generator.title }
  let(:fy2024_title) { HopwaCaper::Generators::Fy2024::Generator.title }

  def hopwa_viewable?(user)
    definitions.url_viewable_by?(hopwa_url, user.reload)
  end

  def create_run(report_name, **attrs)
    create(:hud_reports_report_instance, report_name: report_name, **attrs)
  end

  before do
    definitions.maintain_report_definitions
    Collection.maintain_system_groups(group: :reports)
    AccessGroup.maintain_system_groups(group: :reports)

    # State before the opt-in change: HOPWA CAPER sits in the system HUD collection and group.
    hud_ids = definitions.hud.pluck(:id)
    system_collection = Collection.system_collection(:hud_reports)
    system_collection.set_viewables({ reports: hud_ids })
    AccessControl.create!(role: viewer_role, collection: system_collection, user_group: user_group)
    user_group.add(acl_user)

    system_group = AccessGroup.system_group(:hud_reports)
    system_group.set_viewables({ reports: hud_ids })
    legacy_user.legacy_roles << viewer_role
    legacy_outsider.legacy_roles << viewer_role
    system_group.add(legacy_user)
  end

  context 'when a HOPWA CAPER has been run' do
    before { create_run(fy2026_title) }

    it 'keeps HOPWA CAPER visible to ACL and legacy members and to no one else' do
      expect(hopwa_viewable?(acl_user)).to be true
      expect(hopwa_viewable?(legacy_user)).to be true

      described_class.new.run!

      expect(hopwa_viewable?(acl_user)).to be true
      expect(hopwa_viewable?(legacy_user)).to be true
      expect(hopwa_viewable?(outsider)).to be false
      expect(hopwa_viewable?(legacy_outsider)).to be false
    end

    it 'removes HOPWA CAPER from the All HUD Reports collection and access group' do
      described_class.new.run!

      expect(Collection.system_collection(:hud_reports).report_ids).not_to include(hopwa_definition.id)
      expect(AccessGroup.system_group(:hud_reports).report_ids).not_to include(hopwa_definition.id)
    end

    it 'creates a HOPWA CAPER collection holding only the HOPWA CAPER definition' do
      described_class.new.run!

      collection = Collection.find_by!(name: described_class::NAME)
      expect(collection.report_ids).to contain_exactly(hopwa_definition.id)
    end

    it 'mirrors the user group so users added later also reach HOPWA CAPER' do
      described_class.new.run!
      user_group.add(late_acl_user)

      expect(hopwa_viewable?(late_acl_user)).to be true
    end

    it 'grants through the named role without altering the existing role' do
      described_class.new.run!

      expect(Role.find_by!(name: described_class::ROLE_NAME).can_view_assigned_reports).to be true
      expect(viewer_role.reload.can_view_assigned_reports).to be true
      expect(viewer_role.access_controls.map { |ac| ac.collection.name }).to contain_exactly('All HUD Reports')
    end

    it 'does not mirror a user group whose system-collection role lacks report access' do
      other_user = create(:acl_user)
      other_group = create(:user_group)
      other_group.add(other_user)
      AccessControl.create!(
        role: create(:role, can_view_assigned_reports: false),
        collection: Collection.system_collection(:hud_reports),
        user_group: other_group,
      )
      route_group = create(:user_group)
      route_group.add(other_user)
      unrelated = create(:collection, collection_type: 'Reports')
      AccessControl.create!(role: viewer_role, collection: unrelated, user_group: route_group)
      expect(hopwa_viewable?(other_user)).to be false

      described_class.new.run!

      hopwa_collection = Collection.find_by!(name: described_class::NAME)
      expect(AccessControl.where(collection_id: hopwa_collection.id).pluck(:user_group_id)).to contain_exactly(user_group.id)
      expect(hopwa_viewable?(other_user)).to be false
    end

    it 'leaves an access group already named HOPWA CAPER untouched' do
      existing = AccessGroup.create!(name: described_class::NAME)
      data_source = create(:source_data_source)
      existing.set_viewables({ data_sources: [data_source.id] })
      existing_member = create(:user)
      existing.add(existing_member)

      described_class.new.run!

      existing.reload
      expect(existing.data_source_ids).to contain_exactly(data_source.id)
      expect(existing.users.pluck(:id)).to contain_exactly(existing_member.id)
    end

    it 'does not grant a user whose only access group membership is an unrelated group' do
      other_group = create(:user_group)
      other_group.add(outsider)
      unrelated = create(:collection, collection_type: 'Reports')
      AccessControl.create!(role: viewer_role, collection: unrelated, user_group: other_group)

      described_class.new.run!

      expect(hopwa_viewable?(outsider)).to be false
    end

    it 'leaves no partial grant when a step fails' do
      hopwa_grants = GrdaWarehouse::GroupViewableEntity.where(entity_type: hopwa_definition.class.sti_name, entity_id: hopwa_definition.id)
      grant_ids_before = hopwa_grants.pluck(:id)
      allow(AccessGroup).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

      expect { described_class.new.run! }.to raise_error(ActiveRecord::RecordInvalid)

      expect(Role.with_deleted.where(name: described_class::ROLE_NAME)).to be_empty
      expect(Collection.where(name: described_class::NAME)).to be_empty
      expect(hopwa_grants.pluck(:id)).to match_array(grant_ids_before)
    end
  end

  it 'counts a run of another fiscal year' do
    create_run(fy2024_title)

    described_class.new.run!

    expect(hopwa_viewable?(acl_user)).to be true
    expect(hopwa_viewable?(legacy_user)).to be true
  end

  context 'when no HOPWA CAPER has been run' do
    it 'grants nobody and creates no HOPWA CAPER role, collection, or access group' do
      described_class.new.run!

      expect(Role.where(name: described_class::ROLE_NAME)).to be_empty
      expect(Collection.where(name: described_class::NAME)).to be_empty
      expect(AccessGroup.where(name: described_class::NAME)).to be_empty
      expect(hopwa_viewable?(acl_user)).to be false
      expect(hopwa_viewable?(legacy_user)).to be false
    end
  end

  it 'treats only soft-deleted HOPWA CAPER runs as no run' do
    create_run(fy2026_title).destroy

    described_class.new.run!

    expect(Collection.where(name: described_class::NAME)).to be_empty
    expect(hopwa_viewable?(acl_user)).to be false
  end

  it 'creates one role, collection, and access group when run twice' do
    create_run(fy2026_title)

    2.times { described_class.new.run! }

    expect(Role.with_deleted.where(name: described_class::ROLE_NAME).count).to eq(1)
    expect(Collection.where(name: described_class::NAME).count).to eq(1)
    expect(AccessGroup.where(name: described_class::NAME).count).to eq(1)
    expect(hopwa_viewable?(acl_user)).to be true
    expect(hopwa_viewable?(legacy_user)).to be true
  end

  it 'runs from the TaskQueue key' do
    task = TaskQueue.create!(task_key: :hopwa_caper_grant_existing_access, queued_at: Time.current)
    create_run(fy2026_title)

    task.run!

    expect(task.reload.completed_at).to be_present
    expect(Collection.find_by!(name: described_class::NAME).report_ids).to contain_exactly(hopwa_definition.id)
  end

  it 'ignores runs of other HUD reports' do
    create_run('Annual Performance Report - FY 2026')

    described_class.new.run!

    expect(Collection.where(name: described_class::NAME)).to be_empty
  end
end
