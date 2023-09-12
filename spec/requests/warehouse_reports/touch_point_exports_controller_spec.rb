require 'rails_helper'

RSpec.describe WarehouseReports::TouchPointExportsController, type: :request do
  let!(:no_data_source_collection) { create :collection }
  let!(:report_group) { create :collection }
  let!(:user) { create :acl_user }
  let!(:role) { create :admin_role }
  let!(:report) { create :touch_point_report }

  let!(:other_user) { create :acl_user }
  let!(:other_report_viewer) { create :report_viewer }
  let!(:report_viewer) { create :report_viewer }
  let!(:assigned_report_viewer) { create :assigned_report_viewer }

  describe 'Administrative user' do
    before(:each) do
      add_random_user_with_report_access
      report_group.set_viewables({ reports: [report.id] })
      setup_access_control(user, role, report_group)
      sign_in(user)
    end

    describe 'should be able to access the index path' do
      it 'returns http success' do
        get warehouse_reports_touch_point_exports_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'User with no access to reports' do
    before(:each) do
      add_random_user_with_report_access

      sign_in(user)
    end

    describe 'should not be able to access the index path' do
      it 'and should receive a redirect' do
        get warehouse_reports_touch_point_exports_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'Report viewer' do
    before(:each) do
      add_random_user_with_report_access
      report_group.set_viewables({ reports: [report.id] })
      setup_access_control(user, report_viewer, report_group)
      sign_in(user)
    end

    describe 'should be able to access the index path' do
      it 'returns http success' do
        get warehouse_reports_touch_point_exports_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'Assigned Report viewer' do
    before(:each) do
      add_random_user_with_report_access
      # Remove previously assigned access
      user.user_group_members.delete_all
      setup_access_control(user, assigned_report_viewer, no_data_source_collection)
      sign_in(user)
    end

    describe 'should not be able to access the index path' do
      it 'and should receive a redirect' do
        get warehouse_reports_touch_point_exports_path
        expect(response).to have_http_status(:redirect)
      end
    end

    describe 'should be able to access the index path if the report has been assigned' do
      it 'returns http success' do
        report_group.set_viewables({ reports: [report.id] })
        setup_access_control(user, other_report_viewer, report_group)
        get warehouse_reports_touch_point_exports_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  def add_random_user_with_report_access
    # You have to have someone else in the DB with access
    # to this report or the test passes, but doesn't actually
    # check access correctly
    report_group.set_viewables({ reports: [report.id] })
    setup_access_control(other_user, other_report_viewer, report_group)
  end
end
