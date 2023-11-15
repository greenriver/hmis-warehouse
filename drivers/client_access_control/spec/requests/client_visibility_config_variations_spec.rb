###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require 'shared_contexts/visibility_test_context'
require 'nokogiri'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr'
  c.hook_into :webmock
  c.configure_rspec_metadata!
end

RSpec.describe ClientAccessControl::ClientsController, type: :request, vcr: true do
  include_context 'visibility test context'

  configs_variations = []
  GrdaWarehouse::Config.available_cas_methods.values.product( # cas available method
    [true, false], # consent visible to all
    [true, false], # expose coc code
    GrdaWarehouse::Config.available_health_emergencies.values, # health emergency
    GrdaWarehouse::Config.available_health_emergency_tracings.values, # health emergency tracing
    [0, 20, 65], # health priority age
    [true, false], # multi coc installation
  ) do |combination|
    variation = [
      [
        :cas_available_method,
        :consent_visible_to_all,
        :expose_coc_code,
        :health_emergency,
        :health_emergency_tracing,
        :health_priority_age,
        :multi_coc_installation,
      ], combination
    ].transpose.to_h
    configs_variations.append(variation)
  end

  configs_variations.each do |variation|
    context "when using variable configs #{variation}" do
      before(:all) do
        if variation[:cas_available_method].in?([:project_group, :boston])
          @cas_project_group = GrdaWarehouse::ProjectGroup.new(name: 'test group for cas sync config')
          @cas_project_group.save!
          variation[:cas_sync_project_group_id] = @cas_project_group.id
        end
      end
      after(:all) do
        @cas_project_group.destroy if variation[:cas_available_method].in?([:project_group, :boston])
      end

      before do
        GrdaWarehouse::Config.delete_all
        GrdaWarehouse::Config.invalidate_cache
        GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
        Collection.maintain_system_groups
      end
      let!(:config) { create :config_b, variation }
      let!(:user) { create :acl_user }

      describe 'and the user has a fairly admin-like role' do
        before do
          [
            can_view_clients,
            can_search_own_clients,
            can_view_all_reports,
            can_edit_users,
            can_manage_config,
            can_edit_data_sources,
          ].each do |role|
            setup_access_control(user, role, Collection.system_collection(:data_sources))
            setup_access_control(user, role, Collection.system_collection(:hmis_reports))
          end
          sign_in user
        end

        it 'returns a 200 when visiting various pages' do
          aggregate_failures 'checking pages' do
            get clients_path(q: 'bob')
            expect(response).to have_http_status(200)
            get(warehouse_reports_path)
            expect(response).to have_http_status(200)
            get client_path(window_destination_client)
            expect(response).to have_http_status(200)
            get client_path(non_window_destination_client)
            expect(response).to have_http_status(200)
            get(dashboards_clients_path)
            expect(response).to have_http_status(200)
            get(data_sources_path)
            expect(response).to have_http_status(200)
            get(admin_users_path)
            expect(response).to have_http_status(200)
            get(admin_configs_path)
            expect(response).to have_http_status(200)
          end
        end
      end
    end
  end
end
