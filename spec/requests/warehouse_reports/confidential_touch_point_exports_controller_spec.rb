require 'rails_helper'

RSpec.describe WarehouseReports::ConfidentialTouchPointExportsController, type: :request do
  let!(:no_data_source_collection) { create :collection }
  let!(:report_group) { create :collection }
  let!(:report) { create :confidential_touch_point_report }
  let!(:other_report) { create :touch_point_report }

  let!(:user) { create :acl_user }
  let(:other_user) { create :acl_user }

  let!(:admin_role) { create :health_admin }
  let!(:role) { create :report_viewer }
  let!(:other_report_viewer) { create :report_viewer }
  let!(:role) { create :assigned_report_viewer }

  describe 'Health admin user' do
    before(:each) do
      user.health_roles << admin_role
      add_random_user_with_report_access

      sign_in(user)
    end
    describe 'should not be able to access the index path' do
      it 'and should receive a redirect' do
        get warehouse_reports_confidential_touch_point_exports_path
        expect(response).to have_http_status(:redirect)
      end
    end
    describe 'should be able to access the index path if they can also see the report' do
      it 'returns http success' do
        report_group.set_viewables({ reports: [report.id] })
        setup_access_control(user, other_report_viewer, report_group)
        get warehouse_reports_confidential_touch_point_exports_path
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
        get warehouse_reports_confidential_touch_point_exports_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'Report viewer' do
    before(:each) do
      add_random_user_with_report_access

      setup_access_control(user, role, no_data_source_collection)
      sign_in(user)
    end

    describe 'should not be able to access the index path' do
      it 'and should receive a redirect' do
        get warehouse_reports_confidential_touch_point_exports_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'Assigned Report viewer' do
    before(:each) do
      add_random_user_with_report_access
      setup_access_control(user, role, no_data_source_collection)
      sign_in(user)
    end

    describe 'should not be able to access the index path' do
      it 'and should receive a redirect' do
        get warehouse_reports_confidential_touch_point_exports_path
        expect(response).to have_http_status(:redirect)
      end
    end

    describe 'should not be able to access the index path even if the report has been assigned' do
      it 'and should receive a redirect' do
        report_group.set_viewables({ reports: [report.id] })
        setup_access_control(user, other_report_viewer, report_group)
        get warehouse_reports_confidential_touch_point_exports_path
        expect(response).to have_http_status(:redirect)
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
