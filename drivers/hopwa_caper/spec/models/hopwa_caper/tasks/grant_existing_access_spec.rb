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

    it 'does not re-grant after an admin removes the grant' do
      described_class.new.run!
      AccessControl.where(collection_id: Collection.find_by!(name: described_class::NAME).id).destroy_all

      described_class.new.run!

      expect(hopwa_viewable?(acl_user)).to be false
    end
  end

  it 'counts a run of another fiscal year' do
    create_run(fy2024_title)

    described_class.new.run!

    expect(hopwa_viewable?(acl_user)).to be true
    expect(hopwa_viewable?(legacy_user)).to be true
  end

  context 'when no HOPWA CAPER has been run' do
    it 'grants nobody and creates no HOPWA CAPER collection or access group' do
      described_class.new.run!

      expect(Collection.where(name: described_class::NAME)).to be_empty
      expect(AccessGroup.where(name: described_class::NAME)).to be_empty
      expect(hopwa_viewable?(acl_user)).to be false
      expect(hopwa_viewable?(legacy_user)).to be false
    end

    it 'does not grant on a later run once a report exists' do
      described_class.new.run!
      create_run(fy2026_title)

      described_class.new.run!

      expect(hopwa_viewable?(acl_user)).to be false
    end
  end

  it 'treats only soft-deleted HOPWA CAPER runs as no run' do
    create_run(fy2026_title).destroy

    described_class.new.run!

    expect(Collection.where(name: described_class::NAME)).to be_empty
    expect(hopwa_viewable?(acl_user)).to be false
  end

  it 'ignores runs of other HUD reports' do
    create_run('Annual Performance Report - FY 2026')

    described_class.new.run!

    expect(Collection.where(name: described_class::NAME)).to be_empty
  end
end
