require 'rails_helper'

RSpec.describe ClientAccessControl::HistoryController, type: :request do
  let!(:warehouse_data_source) { create :grda_warehouse_data_source, visible_in_window: true }
  let!(:window_data_source) { create :visible_data_source }
  let!(:destination) do
    create(
      :grda_warehouse_hud_client,
      data_source_id: warehouse_data_source.id,
    )
  end
  let!(:client) do
    create(
      :window_hud_client,
      data_source_id: window_data_source.id,
      SSN: '123456789',
      FirstName: 'First',
      LastName: 'Last',
      DOB: '2019-09-16',
    )
  end
  let!(:warehouse_client) { create :warehouse_client, source: client, destination: destination }

  describe 'logged out' do
    it 'doesn\'t allow show' do
      get client_history_path(destination)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow queue' do
      post queue_client_history_path(destination)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'does not allow pdf if client not set to generate pdf' do
      get pdf_client_history_path(destination)
      aggregate_failures 'validating' do
        expect(response).to have_http_status(302)
        expect(destination.client_files.count).to eq(0)
      end
    end

    it 'allows pdf if client set to generate pdf' do
      destination.update(generate_history_pdf: true)
      get pdf_client_history_path(destination)
      aggregate_failures 'validating' do
        expect(response).to have_http_status(200)
        expect(destination.client_files.count).to eq(1)
      end
    end
  end
end
