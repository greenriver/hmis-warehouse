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

  let!(:user) { create :user }

  let!(:r1) { create :touch_point_report }
  let!(:r2) { create :confidential_touch_point_report }

  let!(:no_reports_access_group) { create :access_group }

  user_ids = ->(user) { model.viewable_by(user).pluck(:id).sort }
  ids      = ->(*reports) { reports.map(&:id).sort }

  describe 'scopes' do
    describe 'viewability' do
      describe 'ordinary user' do
        it 'sees nothing' do
          expect(model.viewable_by(user).exists?).to be false
        end
      end

      describe 'admin user' do
        before do
          setup_access_control(user, admin_role, AccessGroup.where(name: 'All HMIS Reports').first)
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
          no_reports_access_group.set_viewables({ reports: [r1.id] })
          setup_access_control(user, no_permission_role, no_reports_access_group)
        end
        it 'still sees nothing without role' do
          expect(model.viewable_by(user).exists?).to be false
        end
      end

      describe 'user assigned a report with a role granting access' do
        before :each do
          no_reports_access_group.set_viewables({ reports: [r1.id] })
          setup_access_control(user, assigned_report_viewer, no_reports_access_group)
        end
        it 'sees r1 with proper role' do
          expect(user_ids[user]).to eq ids[r1]
        end
      end
    end
  end
end
