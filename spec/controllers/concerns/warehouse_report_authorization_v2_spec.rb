###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WarehouseReportAuthorizationV2, type: :controller do
  after(:each) do
    Rails.application.reload_routes!
  end

  let!(:user) { create :acl_user }
  let!(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      url: 'test_report',
      name: 'Test Report',
      report_group: 'Reports',
      description: 'Test Report',
    )
  end
  let(:reporting_role) { create(:role, can_view_assigned_reports: true) }

  # `index` is the report page whose path names the report definition, `open_action` is skipped,
  # `guarded_open_action` is skipped but has its own authorize_with, and `denied_report_action`
  # runs authorize_report! and an authorize_with that fails.
  def setup_test_controller
    klass = Class.new(ApplicationControllerV2) do
      include WarehouseReportAuthorizationV2

      skip_before_action :authorize_report!, only: [:open_action, :guarded_open_action]
      authorize_with(only: :guarded_open_action) { true }
      authorize_with(only: :denied_report_action) { false }

      def root_action
        render plain: 'root'
      end

      def index
        render plain: 'report'
      end

      def open_action
        render plain: 'open'
      end

      def guarded_open_action
        render plain: 'guarded open'
      end

      def denied_report_action
        render plain: 'denied report'
      end
    end

    @controller = klass.new

    stub_const('TestReportController', klass)
    Rails.application.routes.draw do
      root to: 'test_report#root_action'
      # my_root_path for a user with report permissions
      get 'warehouse_reports' => 'test_report#root_action', as: :warehouse_reports
      get 'test_report' => 'test_report#index'
      get 'open_action' => 'test_report#open_action'
      get 'guarded_open_action' => 'test_report#guarded_open_action'
      get 'denied_report_action' => 'test_report#denied_report_action'
    end
  end

  before(:each) do
    setup_test_controller
    sign_in(user)
  end

  it 'renders the report when a collection holds the report definition' do
    collection = create(:collection)
    collection.set_viewables({ reports: [report_definition.id] })
    setup_access_control(user, reporting_role, collection)

    get :index

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq('report')
  end

  it 'redirects with an alert when no collection holds the report definition' do
    setup_access_control(user, reporting_role, create(:collection))

    get :index

    expect(response).to redirect_to(user.my_root_path)
    expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
  end

  it 'redirects when the collection holds a different report definition' do
    other_definition = GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      url: 'other_report',
      name: 'Other Report',
      report_group: 'Reports',
      description: 'Other Report',
    )
    collection = create(:collection)
    collection.set_viewables({ reports: [other_definition.id] })
    setup_access_control(user, reporting_role, collection)

    get :index

    expect(response).to redirect_to(user.my_root_path)
  end

  it 'redirects an action whose own authorize_with fails even when the report definition is visible' do
    collection = create(:collection)
    collection.set_viewables({ reports: [report_definition.id] })
    setup_access_control(user, reporting_role, collection)

    get :denied_report_action

    expect(response).to redirect_to(user.my_root_path)
    expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
  end

  it 'raises for a skipped action that has no authorize_with of its own' do
    expect { get :open_action }.to raise_error(AuthorizationNotPerformedError)
  end

  it 'runs a skipped action that has its own authorize_with' do
    get :guarded_open_action

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq('guarded open')
  end
end
