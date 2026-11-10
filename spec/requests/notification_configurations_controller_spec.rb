###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Covers both the import threshold and the CSV monitor notification configuration controllers.
RSpec.describe 'Import alert notification configurations', type: :request do
  let(:user) { create(:acl_user) }
  let(:recipient) { create(:user) }
  let(:collection) { create(:collection) }
  let(:data_source) { create(:source_data_source) }
  let(:project) { create(:hud_project, data_source: data_source) }
  let!(:import_threshold) { create(:import_threshold, data_source: data_source) }
  let!(:monitor) { create(:grda_warehouse_import_csv_monitor, data_source: data_source) }
  let!(:threshold_config) do
    create(:notification_configuration_import_threshold, :error_count_notification_event, source: import_threshold, user_id: recipient.id, active: true)
  end
  let!(:monitor_config) do
    create(:notification_configuration_import_threshold, :csv_import_notification_event, source: monitor, user_id: recipient.id, active: true)
  end
  let(:new_recipient) { create(:user) }
  let(:create_params) { { grda_warehouse_notification_configuration: { user_id: new_recipient.id, active: '1' } } }
  let(:update_params) { { grda_warehouse_notification_configuration: { active: '0' } } }

  before { sign_in user }

  def threshold_configs
    GrdaWarehouse::NotificationConfiguration.where(source: import_threshold)
  end

  def monitor_configs
    GrdaWarehouse::NotificationConfiguration.where(source: monitor)
  end

  def create_threshold_config
    post data_source_import_threshold_notification_configurations_path(data_source, notification_slug: 'error_threshold_exceeded'), params: create_params
  end

  def create_monitor_config
    post data_source_import_csv_monitor_notification_configurations_path(data_source, monitor), params: create_params
  end

  def threshold_config_unchanged?
    threshold_configs.count == 1 && threshold_config.reload.active
  end

  def monitor_config_unchanged?
    monitor_configs.count == 1 && monitor_config.reload.active
  end

  # A user who can't see the data source gets a 404 from the load before the write check runs, so
  # these examples can't catch an action that skips require_can_edit_import_alerts!. The 'with view
  # access to one project of the data source' context does: it hits every action of both controllers
  # and expects a redirect. A not-found response drops the sign-in session, so each example makes one
  # request.
  context 'with no rights' do
    describe NotificationConfigurationsController do
      it 'denies new' do
        get new_data_source_import_threshold_notification_configuration_path(data_source, notification_slug: 'error_threshold_exceeded')
        expect(response).to have_http_status(:not_found)
      end

      it 'denies create' do
        create_threshold_config
        expect(response).to have_http_status(:not_found)
        expect(threshold_config_unchanged?).to be(true)
      end

      it 'denies edit' do
        get edit_data_source_import_threshold_notification_configuration_path(data_source, threshold_config)
        expect(response).to have_http_status(:not_found)
      end

      it 'denies update' do
        patch data_source_import_threshold_notification_configuration_path(data_source, threshold_config), params: update_params
        expect(response).to have_http_status(:not_found)
        expect(threshold_config_unchanged?).to be(true)
      end

      it 'denies destroy' do
        delete data_source_import_threshold_notification_configuration_path(data_source, threshold_config)
        expect(response).to have_http_status(:not_found)
        expect(threshold_config_unchanged?).to be(true)
      end
    end

    describe ImportCsvMonitors::NotificationConfigurationsController do
      it 'denies new' do
        get new_data_source_import_csv_monitor_notification_configuration_path(data_source, monitor)
        expect(response).to have_http_status(:not_found)
      end

      it 'denies create' do
        create_monitor_config
        expect(response).to have_http_status(:not_found)
        expect(monitor_config_unchanged?).to be(true)
      end

      it 'denies edit' do
        get edit_data_source_import_csv_monitor_notification_configuration_path(data_source, monitor, monitor_config)
        expect(response).to have_http_status(:not_found)
      end

      it 'denies update' do
        patch data_source_import_csv_monitor_notification_configuration_path(data_source, monitor, monitor_config), params: update_params
        expect(response).to have_http_status(:not_found)
        expect(monitor_config_unchanged?).to be(true)
      end

      it 'denies destroy' do
        delete data_source_import_csv_monitor_notification_configuration_path(data_source, monitor, monitor_config)
        expect(response).to have_http_status(:not_found)
        expect(monitor_config_unchanged?).to be(true)
      end
    end
  end

  context 'with view access to one project of the data source' do
    before do
      collection.set_viewables({ projects: [project.id] })
      setup_access_control(user, create(:role, can_view_projects: true), collection)
    end

    it 'does not add or remove threshold recipients' do
      expect { create_threshold_config }.not_to(change { threshold_configs.count })
      expect(response).to redirect_to(root_path)

      delete data_source_import_threshold_notification_configuration_path(data_source, threshold_config)
      expect(response).to redirect_to(root_path)
      expect(threshold_configs).to exist(threshold_config.id)
    end

    it 'does not add or remove CSV monitor recipients' do
      expect { create_monitor_config }.not_to(change { monitor_configs.count })
      expect(response).to redirect_to(root_path)

      delete data_source_import_csv_monitor_notification_configuration_path(data_source, monitor, monitor_config)
      expect(response).to redirect_to(root_path)
      expect(monitor_configs).to exist(monitor_config.id)
    end

    it 'does not show the threshold recipient forms or update a recipient' do
      get new_data_source_import_threshold_notification_configuration_path(data_source, notification_slug: 'error_threshold_exceeded')
      expect(response).to redirect_to(root_path)
      get edit_data_source_import_threshold_notification_configuration_path(data_source, threshold_config)
      expect(response).to redirect_to(root_path)
      patch data_source_import_threshold_notification_configuration_path(data_source, threshold_config), params: update_params
      expect(response).to redirect_to(root_path)
      expect(threshold_config_unchanged?).to be(true)
    end

    it 'does not show the CSV monitor recipient forms or update a recipient' do
      get new_data_source_import_csv_monitor_notification_configuration_path(data_source, monitor)
      expect(response).to redirect_to(root_path)
      get edit_data_source_import_csv_monitor_notification_configuration_path(data_source, monitor, monitor_config)
      expect(response).to redirect_to(root_path)
      patch data_source_import_csv_monitor_notification_configuration_path(data_source, monitor, monitor_config), params: update_params
      expect(response).to redirect_to(root_path)
      expect(monitor_config_unchanged?).to be(true)
    end
  end

  context 'with the edit permission only in a collection that does not include the data source' do
    let(:editable_data_source) { create(:source_data_source) }

    before do
      collection.set_viewables({ projects: [project.id] })
      setup_access_control(user, create(:role, can_view_projects: true), collection)
      other_collection = create(:collection)
      other_collection.set_viewables({ data_sources: [editable_data_source.id] })
      setup_access_control(user, create(:role, can_view_projects: true, can_edit_data_sources: true), other_collection)
    end

    it 'does not add threshold recipients' do
      expect { create_threshold_config }.not_to(change { threshold_configs.count })
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it 'does not add CSV monitor recipients' do
      expect { create_monitor_config }.not_to(change { monitor_configs.count })
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    # The data source in the URL is editable, but the record belongs to another data source.
    # A not-found response drops the sign-in session, so each example makes one such request.
    it "does not remove this data source's threshold recipient through the URL of an editable one" do
      create(:import_threshold, data_source: editable_data_source)

      delete data_source_import_threshold_notification_configuration_path(editable_data_source, threshold_config)
      expect(response).to have_http_status(:not_found)
      expect(threshold_configs).to exist(threshold_config.id)
    end

    it "does not remove this data source's CSV monitor recipient through the URL of an editable one" do
      editable_monitor = create(:grda_warehouse_import_csv_monitor, data_source: editable_data_source)

      delete data_source_import_csv_monitor_notification_configuration_path(editable_data_source, editable_monitor, monitor_config)
      expect(response).to have_http_status(:not_found)
      expect(monitor_configs).to exist(monitor_config.id)
    end
  end

  context 'with the warehouse alerts permission and view access to one project' do
    before do
      collection.set_viewables({ projects: [project.id] })
      setup_access_control(user, create(:role, can_view_projects: true, can_edit_warehouse_alerts: true), collection)
    end

    it 'adds threshold and CSV monitor recipients' do
      expect { create_threshold_config }.to change { threshold_configs.count }.by(1)
      expect { create_monitor_config }.to change { monitor_configs.count }.by(1)
    end
  end

  context 'with the edit permission on the data source' do
    before do
      collection.set_viewables({ data_sources: [data_source.id] })
      setup_access_control(user, create(:role, can_view_projects: true, can_edit_data_sources: true), collection)
    end

    it 'adds and removes threshold recipients' do
      expect { create_threshold_config }.to change { threshold_configs.count }.by(1)
      delete data_source_import_threshold_notification_configuration_path(data_source, threshold_config)
      expect(threshold_configs).not_to exist(threshold_config.id)
    end

    it 'adds and removes CSV monitor recipients' do
      expect { create_monitor_config }.to change { monitor_configs.count }.by(1)
      delete data_source_import_csv_monitor_notification_configuration_path(data_source, monitor, monitor_config)
      expect(monitor_configs).not_to exist(monitor_config.id)
    end
  end
end
