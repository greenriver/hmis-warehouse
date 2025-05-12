###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe CoreDemographicsReport::WarehouseReports::CoreController, type: :request do
  let(:agency) { create :agency }
  let(:role) { create :admin_role, can_view_projects: true }
  let(:user) { create :user, agency: agency }
  let!(:report) { create :core_demographics_report }

  before do
    GrdaWarehouse::Config.delete_all
    GrdaWarehouse::Config.invalidate_cache
    GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
    AccessGroup.maintain_system_groups
    sign_in user
  end

  let(:data_source) { create :source_data_source }
  let(:organization) { create :hud_organization, data_source: data_source }
  let(:projects) do
    3.times.map do
      create :grda_warehouse_hud_project, data_source: data_source, organization: organization
    end
  end

  context 'with project and data set access' do
    before(:each) do
      user.legacy_roles = [role]
      user.add_viewable(report)
      user.add_viewable(organization)
      projects.each { |p| user.add_viewable(p) }
    end

    it 'resolves index' do
      get core_demographics_report_warehouse_reports_core_index_path
      expect(response).to be_successful
      expect(assigns(:report)).to be_an_instance_of(CoreDemographicsReport::Core)

      # check queries once the cache is warm
      expect do
        get core_demographics_report_warehouse_reports_core_index_path
      end.to make_database_queries(
        count: 10..40,
        matching: /\A(?!.*SELECT "translations".* FROM "translations")/, # exclude translations
      )
    end
  end

  context 'without any access' do
    it 'denies access' do
      get core_demographics_report_warehouse_reports_core_index_path
      expect(response).to redirect_to(root_path)
    end
  end
end
