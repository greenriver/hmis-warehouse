###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cache-Control headers for authenticated responses', type: :request do
  let(:user) { create :user }

  describe 'warehouse controllers' do
    context 'when authenticated' do
      before do
        sign_in user
        get root_path
      end

      it 'sets no-store Cache-Control' do
        expect(response.headers['Cache-Control']).to include('no-store')
      end

      it 'sets Pragma no-cache' do
        expect(response.headers['Pragma']).to eq('no-cache')
      end

      it 'sets a past Expires date' do
        expect(response.headers['Expires']).to be_present
      end
    end

    context 'when not authenticated' do
      before { get new_user_session_path }

      it 'does not set no-store Cache-Control' do
        expect(response.headers['Cache-Control']).not_to include('no-store')
      end

      it 'does not set Pragma no-cache' do
        expect(response.headers['Pragma']).to be_nil
      end
    end
  end

  describe 'image endpoint (skip_before_action)' do
    let(:destination) { create :grda_warehouse_hud_client }
    let(:client) { create :grda_warehouse_hud_client }
    let!(:warehouse_client) { create :warehouse_client, source: client, destination: destination }

    before do
      sign_in user
      get image_source_client_path(client)
    end

    it 'does not set no-store Cache-Control' do
      expect(response.headers['Cache-Control']).not_to include('no-store')
    end
  end
end
