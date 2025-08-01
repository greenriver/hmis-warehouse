###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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

  let!(:user) { create :user }

  let!(:r1) { create :touch_point_report }
  let!(:r2) { create :confidential_touch_point_report }

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
          user.legacy_roles << admin_role
        end
        after do
          user.legacy_roles = []
        end
        it 'sees none' do
          expect(user_ids[user]).to be_empty
        end
      end

      describe 'user assigned a report without a role granting access' do
        before :each do
          user.add_viewable(r1)
        end
        it 'still sees nothing without role' do
          expect(model.viewable_by(user).exists?).to be false
        end
      end

      describe 'user assigned a report with a role granting access' do
        before :each do
          user.legacy_roles << assigned_report_viewer
          user.add_viewable(r1)
        end
        it 'sees r1 with proper role' do
          expect(user_ids[user]).to eq ids[r1]
        end
      end
    end
  end

  describe PerformanceMeasurement::Report, type: :model do
    let(:user) { create :user }
    let(:other_user) { create :user }
    let(:admin_user) { create :user }

    let!(:admin_report) { create :simple_reports_report_instance, type: 'PerformanceMeasurement::Report', user_id: admin_user.id }
    let!(:other_report) { create :simple_reports_report_instance, type: 'PerformanceMeasurement::Report', user_id: other_user.id }

    before do
      admin_user.legacy_roles << admin_role
      other_user.legacy_roles << assigned_report_viewer
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
