###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

model = GrdaWarehouse::WarehouseReports::ReportDefinition
RSpec.describe model, type: :model do
  let!(:ensure_no_reports_from_migration) do
    # migrations add reports to the report table, sometimes these show up in testing
    # on travis, we use schema load, so this is not a problem
    GrdaWarehouse::WarehouseReports::ReportDefinition.delete_all
  end
  let!(:admin_role) { create :admin_role }
  let!(:assigned_report_viewer) { create :assigned_report_viewer }
  let!(:no_permission_role) { create :role }

  let!(:user) { create :acl_user }

  let!(:r1) { create :touch_point_report }
  let!(:r2) { create :hmis_export_report }

  let!(:no_reports_collection) { create :collection }

  user_ids = ->(user) { model.viewable_by(user).pluck(:id).sort }
  ids      = ->(*reports) { reports.map(&:id).sort }

  describe '#new_report?' do
    it 'is true for recently created reports but never for HUD reports' do
      expect(r1.new_report?).to be true
      r1.update!(report_group: model::HUD_REPORT_GROUP)
      expect(r1.new_report?).to be false
    end
  end

  describe 'scopes' do
    describe 'viewability' do
      describe 'ordinary user' do
        it 'sees nothing' do
          expect(model.viewable_by(user).exists?).to be false
        end
      end

      describe 'admin user' do
        before do
          Collection.maintain_system_groups
          setup_access_control(user, admin_role, Collection.system_collection(:hmis_reports))
        end
        after do
          user.user_group_members.destroy_all
        end
        it 'sees both' do
          expect(user_ids[user]).to eq ids[r1, r2]
        end
      end

      describe 'user assigned a report without a role granting access' do
        before :each do
          no_reports_collection.set_viewables({ reports: [r1.id] })
          setup_access_control(user, no_permission_role, no_reports_collection)
        end
        it 'still sees nothing without role' do
          expect(model.viewable_by(user).exists?).to be false
        end
      end

      describe 'user assigned a report with a role granting access' do
        before :each do
          no_reports_collection.set_viewables({ reports: [r1.id] })
          setup_access_control(user, assigned_report_viewer, no_reports_collection)
        end
        it 'sees r1 with proper role' do
          expect(user_ids[user]).to eq ids[r1]
        end
      end
    end
  end

  describe 'HUD report definitions' do
    before { model.maintain_report_definitions }

    it 'seeds one definition per HUD report controller in the HUD Reports group' do
      expect(model.hud.pluck(:url)).to contain_exactly(
        'hud_reports/aprs', 'hud_reports/capers', 'hud_reports/ce_aprs', 'hud_reports/dqs',
        'hud_reports/spms', 'hud_reports/pits', 'hud_reports/hics', 'hud_reports/lsas',
        'hud_reports/paths', 'hud_reports/hopwa_capers'
      )
    end

    describe '.url_viewable_by?' do
      let(:apr) { model.find_by!(url: 'hud_reports/aprs') }
      let(:collection) { create(:collection, collection_type: 'Reports') }

      it 'is true only for a url in a collection granted with can_view_assigned_reports' do
        collection.set_viewables(reports: [apr.id])
        setup_access_control(user, create(:role, can_view_assigned_reports: true), collection)

        expect(model.url_viewable_by?('hud_reports/aprs', user)).to be true
        expect(model.url_viewable_by?('hud_reports/spms', user)).to be false
      end

      it 'is false when the role lacks can_view_assigned_reports even if the report is in the collection' do
        collection.set_viewables(reports: [apr.id])
        setup_access_control(user, create(:role, can_view_all_hud_reports: true), collection)

        expect(model.url_viewable_by?('hud_reports/aprs', user)).to be false
      end
    end
  end

  describe PerformanceMeasurement::Report, type: :model do
    let(:user) { create :acl_user }
    let(:other_user) { create :acl_user }
    let(:admin_user) { create :acl_user }
    let!(:admin_report) { create :simple_reports_report_instance, type: 'PerformanceMeasurement::Report', user_id: admin_user.id }
    let!(:other_report) { create :simple_reports_report_instance, type: 'PerformanceMeasurement::Report', user_id: other_user.id }
    let!(:collection) { create(:collection) }

    before do
      setup_access_control(admin_user, admin_role, collection)
      setup_access_control(other_user, assigned_report_viewer, collection)
    end

    it 'admin can see results of other user\'s scorecard' do
      expect(PerformanceMeasurement::Report.visible_to(admin_user).pluck(:id)).to include(other_report.id)
    end

    it 'admin can see results of their own scorecard' do
      expect(PerformanceMeasurement::Report.visible_to(admin_user).pluck(:id)).to include(admin_report.id)
    end

    it 'other user cannot see results of admin\'s scorecard' do
      expect(PerformanceMeasurement::Report.visible_to(other_user).pluck(:id)).not_to include(admin_report.id)
    end
  end
end
