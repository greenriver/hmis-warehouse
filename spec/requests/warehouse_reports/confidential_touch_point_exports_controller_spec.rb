require 'rails_helper'

RSpec.describe WarehouseReports::ConfidentialTouchPointExportsController, type: :request do
  describe 'Health admin user' do
    let(:user) { create :user }
    let(:admin_role) { create :health_admin }

    let!(:report) { create :confidential_touch_point_report }
    let!(:other_report) { create :touch_point_report }

    let(:other_user) { create :user }
    let(:other_report_viewer) { create :report_viewer }

    before(:each) do
      user.roles << admin_role
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
        user.add_viewable(report)
        get warehouse_reports_confidential_touch_point_exports_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'User with no access to reports' do
    let(:user) { create :user }
    let!(:report) { create :confidential_touch_point_report }

    let(:other_user) { create :user }
    let(:other_report_viewer) { create :report_viewer }

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
    let(:user) { create :user }
    let(:role) { create :report_viewer }
    let!(:report) { create :confidential_touch_point_report }

    let(:other_user) { create :user }
    let(:other_report_viewer) { create :report_viewer }

    before(:each) do
      add_random_user_with_report_access

      user.roles << role
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
    let(:user) { create :user }
    let(:role) { create :assigned_report_viewer }
    let(:report) { create :confidential_touch_point_report }

    let(:other_user) { create :user }
    let(:other_report_viewer) { create :report_viewer }

    before(:each) do
      add_random_user_with_report_access
      user.roles << role
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
        user.add_viewable(report)
        get warehouse_reports_confidential_touch_point_exports_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  def add_random_user_with_report_access
    # You have to have someone else in the DB with access
    # to this report or the test passes, but doesn't actually
    # check access correctly
    other_user.roles << other_report_viewer
    other_user.add_viewable(report)
  end
end
