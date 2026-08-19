###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'nokogiri'

RSpec.describe Admin::ConfigsController, type: :request do
  let!(:user) { create :acl_user }
  let!(:role) { create :admin_role }
  let!(:collection) { create :collection }

  # Admin::ConfigsController#set_config works on the row with id 1, while
  # GrdaWarehouse::Config.get reads the first row. Pin them to one record so the
  # persisted value and the value the dashboard reads cannot diverge.
  let!(:config) { GrdaWarehouse::Config.where(id: 1).first_or_create }

  before do
    GrdaWarehouse::Config.where.not(id: 1).delete_all
    GrdaWarehouse::Config.invalidate_cache
  end

  after do
    GrdaWarehouse::Config.invalidate_cache
  end

  def visible_keys
    GrdaWarehouse::Config.invalidate_cache
    GrdaWarehouse::ClientDemographicColumns.visible.map { |column| column[:key] }
  end

  context 'as an admin who can manage config' do
    before do
      setup_access_control(user, role, collection)
      sign_in user
    end

    describe 'PATCH #update' do
      it 'persists the selected demographic columns' do
        # Without a `client_demographic_columns: []` entry in known_configs, strong params
        # drop the array silently and the request still redirects, so assert the stored value.
        patch admin_configs_path, params: { grda_warehouse_config: { client_demographic_columns: ['name', 'sex'] } }

        expect(config.reload.client_demographic_columns).to eq(['name', 'sex'])
      end

      it 'ignores the blank entry the multi-select posts alongside the real selections' do
        patch admin_configs_path, params: { grda_warehouse_config: { client_demographic_columns: ['', 'name', 'sex'] } }

        expect(visible_keys).to eq(['name', 'sex'])
      end

      it 'falls back to the default columns when an admin clears the picker' do
        config.update!(client_demographic_columns: ['name', 'sex'])
        GrdaWarehouse::Config.invalidate_cache

        patch admin_configs_path, params: { grda_warehouse_config: { client_demographic_columns: [''] } }

        expect(config.reload.client_demographic_columns).not_to include('sex')
        expect(visible_keys).to eq(['name', 'ssn', 'dob', 'gender', 'race', 'veteran_status'])
      end

      it 'leaves the other configs alone when only the demographic columns are submitted' do
        config.update!(client_dashboard: 'boston')
        GrdaWarehouse::Config.invalidate_cache

        patch admin_configs_path, params: { grda_warehouse_config: { client_demographic_columns: ['name'] } }

        expect(config.reload.client_dashboard).to eq('boston')
        expect(config.client_demographic_columns).to eq(['name'])
      end
    end

    describe 'GET #index' do
      it 'renders a multi-select offering every configurable demographic column' do
        get admin_configs_path
        picker = Nokogiri::HTML(response.body).
          at_css("select[name='grda_warehouse_config[client_demographic_columns][]']")

        expect(picker).not_to be_nil, 'expected a client_demographic_columns multi-select on the site config page'
        expect(picker.attributes).to have_key('multiple')
        expect(picker.css('option').map { |option| option['value'] }).
          to include('name', 'ssn', 'dob', 'sex', 'gender', 'race', 'veteran_status')
      end

      it 'marks the currently configured columns as selected' do
        config.update!(client_demographic_columns: ['name', 'sex'])
        GrdaWarehouse::Config.invalidate_cache

        get admin_configs_path
        picker = Nokogiri::HTML(response.body).
          at_css("select[name='grda_warehouse_config[client_demographic_columns][]']")

        expect(picker).not_to be_nil, 'expected a client_demographic_columns multi-select on the site config page'
        expect(picker.css('option[selected]').map { |option| option['value'] }).to contain_exactly('name', 'sex')
      end
    end
  end

  context 'as a user who cannot manage config' do
    before do
      sign_in user
    end

    it 'does not let them change the demographic columns' do
      config.update!(client_demographic_columns: ['name'])
      GrdaWarehouse::Config.invalidate_cache

      patch admin_configs_path, params: { grda_warehouse_config: { client_demographic_columns: ['name', 'sex'] } }

      expect(config.reload.client_demographic_columns).to eq(['name'])
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'does not show them the site config page' do
      get admin_configs_path

      expect(response).to redirect_to(user.my_root_path)
    end
  end
end
