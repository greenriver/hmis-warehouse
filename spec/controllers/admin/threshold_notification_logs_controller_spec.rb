###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ThresholdNotificationLogsController, type: :controller do
  let(:user) { create(:acl_user) }
  let(:admin_user) { create(:acl_user) }
  let(:role) { create(:role, can_audit_users: true) }

  before do
    Collection.maintain_system_groups
    setup_access_control(admin_user, role, Collection.system_collection(:data_sources))
    sign_in admin_user
  end

  describe 'GET #index' do
    context 'with no existing logs or messages' do
      it 'returns http success' do
        get :index, params: { user_id: user.id }
        expect(response).to be_successful
      end

      it 'assigns the target user' do
        get :index, params: { user_id: user.id }
        expect(assigns(:user)).to eq(user)
      end

      it 'assigns empty logs' do
        get :index, params: { user_id: user.id }
        expect(assigns(:logs)).to be_empty
      end
    end

    context 'with existing ThresholdNotificationLog records' do
      let!(:log) do
        create(
          :grda_warehouse_monitoring_threshold_notification_log,
          user_id: user.id,
          sent_at: 1.day.ago,
        )
      end

      it 'assigns paginated logs for the user' do
        get :index, params: { user_id: user.id }
        expect(assigns(:logs)).to include(log)
      end
    end

    context 'without permission' do
      before { sign_in user }

      it 'redirects to root' do
        get :index, params: { user_id: user.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET #show' do
    let!(:log) do
      create(
        :grda_warehouse_monitoring_threshold_notification_log,
        user_id: user.id,
      )
    end

    it 'returns http success' do
      get :show, params: { user_id: user.id, id: log.id }
      expect(response).to be_successful
    end

    it 'assigns the log' do
      get :show, params: { user_id: user.id, id: log.id }
      expect(assigns(:log)).to eq(log)
    end

    context 'when log has an associated message' do
      let!(:message) { create(:message, user: user) }
      let!(:log_with_message) do
        create(
          :grda_warehouse_monitoring_threshold_notification_log,
          user_id: user.id,
          message_id: message.id,
        )
      end

      it 'assigns the message' do
        get :show, params: { user_id: user.id, id: log_with_message.id }
        expect(assigns(:message)).to eq(message)
      end
    end
  end
end
