require 'rails_helper'

model = GrdaWarehouse::WarehouseReports::ReportDefinition
RSpec.describe model, type: :model do
  let!(:ensure_no_reports_from_migration) {
    # migrations add reports to the report table, sometimes these show up in testing
    # on travis, we use schema load, so this is not a problem
    GrdaWarehouse::WarehouseReports::ReportDefinition.delete_all
  }
  let!(:admin_role) { create :admin_role }
  let!(:assigned_report_viewer) { create :assigned_report_viewer }

  let!(:user) { create :user }

  let!(:r1) { create :touch_point_report }
  let!(:r2) { create :confidential_touch_point_report }

  user_ids = -> (user) { model.viewable_by(user).pluck(:id).sort }
  ids      = -> (*reports) { reports.map(&:id).sort }

  describe 'scopes' do
    describe 'viewability' do

      describe 'ordinary user' do
        it 'sees nothing' do
          expect(model.viewable_by(user).exists?).to be false
        end
      end

      describe 'admin user' do
        before do
          user.roles << admin_role
        end
        after do
          user.roles = []
        end
        it 'sees both' do
          expect(user_ids[user]).to eq ids[ r1, r2 ]
        end
      end

      describe 'user assigned a report' do
        before :each do
          user.entities.create entity: r1
        end
        after :each do
          user.entities.destroy_all
          user.roles = []
          user.save
        end
        it 'still sees nothing without role' do
          expect(model.viewable_by(user).exists?).to be false
        end
        it 'sees r1 with proper role' do
          user.roles << assigned_report_viewer
          user.save
          expect(user_ids[user]).to eq ids[r1]
        end
      end

    end
  end


end
