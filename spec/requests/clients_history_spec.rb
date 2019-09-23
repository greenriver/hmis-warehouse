require 'rails_helper'

RSpec.describe Clients::HistoryController, type: :request do
  let!(:warehouse_data_source) { create :grda_warehouse_data_source, visible_in_window: true }
  let!(:window_data_source) { create :visible_data_source }
  let!(:destination) { create :grda_warehouse_hud_client, data_source_id: warehouse_data_source.id }
  let!(:client) { create :window_hud_client, data_source_id: window_data_source.id, SSN: '123456789', FirstName: 'First', LastName: 'Last', DOB: '2019-09-16' }
  let!(:warehouse_client) { create :warehouse_client, source: client, destination: destination }

  describe 'logged out' do
    it 'doesn\'t allow show' do
      get client_history_path(destination)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\`t allow queue' do
      post queue_client_history_path(destination)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'allows pdf' do
      get pdf_client_history_path(destination)
      expect(response).to have_http_status(200)
    end
  end
end
