###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataSourcesController, type: :request do
  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_projects: true) }
  let(:collection) { create(:collection) }
  let(:data_source) { create(:source_data_source) }
  let!(:export) { create(:hud_export, data_source: data_source, ExportID: 'DS1') }

  describe 'GET #organizations' do
    it 'redirects unauthenticated users to sign in' do
      expect_unauthenticated_warehouse_request do
        get organizations_data_source_path(data_source)
      end
    end

    it 'denies users who cannot view projects, organizations, or imports' do
      sign_in user
      get organizations_data_source_path(data_source)
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'with permission to view the data source' do
    before do
      collection.set_viewables({ data_sources: [data_source.id] })
      setup_access_control(user, role, collection)
      sign_in user
    end

    context 'when the data source has more than two CoC codes' do
      let!(:org_alpha) { create(:hud_organization, data_source: data_source, OrganizationName: 'Alpha Housing') }
      let!(:org_beta) { create(:hud_organization, data_source: data_source, OrganizationName: 'Beta Services') }
      let!(:other_data_source) { create(:source_data_source, name: 'Other Vendor') }
      let!(:other_export) { create(:hud_export, data_source: other_data_source, ExportID: 'DS2') }
      let!(:other_org) { create(:hud_organization, data_source: other_data_source, OrganizationName: 'Other CoC Org') }

      let!(:project_ma500) do
        create(:hud_project, data_source: data_source, OrganizationID: org_alpha.OrganizationID, ProjectName: 'Shelter MA-500')
      end
      let!(:project_ma502) do
        create(:hud_project, data_source: data_source, OrganizationID: org_alpha.OrganizationID, ProjectName: 'RRH MA-502')
      end
      let!(:project_ma504) do
        create(:hud_project, data_source: data_source, OrganizationID: org_beta.OrganizationID, ProjectName: 'TH MA-504')
      end
      let!(:project_unknown) do
        create(:hud_project, data_source: data_source, OrganizationID: org_beta.OrganizationID, ProjectName: 'Unknown Coc Project')
      end
      let!(:other_project) do
        create(:hud_project, data_source: other_data_source, OrganizationID: other_org.OrganizationID, ProjectName: 'Foreign Project')
      end

      before do
        create(:hud_project_coc, project: project_ma500, ProjectID: project_ma500.ProjectID, data_source: data_source, CoCCode: 'MA-500')
        create(:hud_project_coc, project: project_ma502, ProjectID: project_ma502.ProjectID, data_source: data_source, CoCCode: 'MA-502')
        create(:hud_project_coc, project: project_ma504, ProjectID: project_ma504.ProjectID, data_source: data_source, CoCCode: 'MA-504')
        create(:hud_project_coc, project: project_unknown, ProjectID: project_unknown.ProjectID, data_source: data_source, CoCCode: nil)
        create(:hud_project_coc, project: other_project, ProjectID: other_project.ProjectID, data_source: other_data_source, CoCCode: 'XX-999')
      end

      describe 'GET #show' do
        it 'shows the CoC picker and prompt instead of organizations' do
          get data_source_path(data_source)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('name="coc_code"')
          expect(response.body).to include('data-controller')
          expect(response.body).to include('content-loader')
          expect(response.body).to include(organizations_data_source_path(data_source))
          expect(response.body).to include('Choose a CoC Code to view organizations and projects.')
          expect(response.body).not_to include('Alpha Housing')
          expect(response.body).not_to include('Beta Services')
        end

        it 'includes Unknown CoC when a ProjectCoC CoCCode is blank' do
          get data_source_path(data_source)
          expect(response.body).to include('Unknown CoC')
        end
      end

      describe 'GET #organizations' do
        it 'includes only projects in the requested CoC from this data source' do
          get organizations_data_source_path(data_source, params: { coc_code: 'MA-500' })
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Alpha Housing')
          expect(response.body).to include('Shelter MA-500')
          expect(response.body).not_to include('RRH MA-502')
          expect(response.body).not_to include('TH MA-504')
          expect(response.body).not_to include('Unknown Coc Project')
          expect(response.body).not_to include('Other CoC Org')
          expect(response.body).not_to include('Foreign Project')
        end

        it 'includes only projects with a blank CoCCode when unknown is requested' do
          get organizations_data_source_path(data_source, params: { coc_code: 'unknown' })
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Unknown Coc Project')
          expect(response.body).to include('Beta Services')
          expect(response.body).not_to include('Shelter MA-500')
          expect(response.body).not_to include('RRH MA-502')
          expect(response.body).not_to include('TH MA-504')
        end

        it 'does not serve organizations for a data source the user cannot view' do
          get organizations_data_source_path(other_data_source, params: { coc_code: 'XX-999' })
          expect(response).to have_http_status(:not_found)
        end

        it 'rejects the request when no CoC code is given and a choice is required' do
          get organizations_data_source_path(data_source)
          expect(response).to have_http_status(:bad_request)
          expect(response.body).not_to include('Alpha Housing')
        end
      end

      describe 'GET #show via the bookmarkable CoC-code URL' do
        it 'pre-selects the requested CoC code and preloads its organizations' do
          get data_source_with_coc_code_path(data_source, 'MA-500')
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('<option selected="selected" value="MA-500">')
          expect(response.body).to include('Alpha Housing')
          expect(response.body).to include('Shelter MA-500')
          expect(response.body).not_to include('RRH MA-502')
          expect(response.body).not_to include('TH MA-504')
          expect(response.body).not_to include('Unknown Coc Project')
        end
      end
    end

    context 'when the data source is small and one CoC dominates' do
      let!(:org) { create(:hud_organization, data_source: data_source, OrganizationName: 'Dominant Coc Org') }
      let!(:project_one) do
        create(:hud_project, data_source: data_source, OrganizationID: org.OrganizationID, ProjectName: 'First Dominant Coc Project')
      end
      let!(:project_two) do
        create(:hud_project, data_source: data_source, OrganizationID: org.OrganizationID, ProjectName: 'Second Dominant Coc Project')
      end
      let!(:project_three) do
        create(:hud_project, data_source: data_source, OrganizationID: org.OrganizationID, ProjectName: 'Third Dominant Coc Project')
      end
      let!(:project_minority) do
        create(:hud_project, data_source: data_source, OrganizationID: org.OrganizationID, ProjectName: 'Minority Coc Project')
      end

      before do
        [project_one, project_two, project_three].each do |project|
          create(:hud_project_coc, project: project, ProjectID: project.ProjectID, data_source: data_source, CoCCode: 'MA-500')
        end
        create(:hud_project_coc, project: project_minority, ProjectID: project_minority.ProjectID, data_source: data_source, CoCCode: 'MA-502')
      end

      it 'lists organizations without a CoC picker' do
        get data_source_path(data_source)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Dominant Coc Org')
        expect(response.body).to include('First Dominant Coc Project')
        expect(response.body).not_to include('name="coc_code"')
        expect(response.body).not_to include('Choose a CoC Code to view organizations and projects.')
      end
    end

    context 'when the data source is small but CoC codes are evenly split' do
      let!(:org) { create(:hud_organization, data_source: data_source, OrganizationName: 'Split Coc Org') }
      let!(:project_one) do
        create(:hud_project, data_source: data_source, OrganizationID: org.OrganizationID, ProjectName: 'First Split Coc Project')
      end
      let!(:project_two) do
        create(:hud_project, data_source: data_source, OrganizationID: org.OrganizationID, ProjectName: 'Second Split Coc Project')
      end

      before do
        create(:hud_project_coc, project: project_one, ProjectID: project_one.ProjectID, data_source: data_source, CoCCode: 'MA-500')
        create(:hud_project_coc, project: project_two, ProjectID: project_two.ProjectID, data_source: data_source, CoCCode: 'MA-502')
      end

      it 'shows the CoC picker instead of organizations' do
        get data_source_path(data_source)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('name="coc_code"')
        expect(response.body).to include('Choose a CoC Code to view organizations and projects.')
        expect(response.body).not_to include('Split Coc Org')
      end
    end

    context "when the user cannot view all of the data source's projects" do
      let!(:visible_org) { create(:hud_organization, data_source: data_source, OrganizationName: 'Visible Org') }
      let!(:hidden_org) { create(:hud_organization, data_source: data_source, OrganizationName: 'Hidden Org') }
      let!(:visible_project) do
        create(:hud_project, data_source: data_source, OrganizationID: visible_org.OrganizationID, ProjectName: 'Visible Project')
      end
      let!(:hidden_project) do
        create(:hud_project, data_source: data_source, OrganizationID: hidden_org.OrganizationID, ProjectName: 'Hidden Project')
      end

      before do
        create(:hud_project_coc, project: visible_project, ProjectID: visible_project.ProjectID, data_source: data_source, CoCCode: 'MA-500')
        create(:hud_project_coc, project: hidden_project, ProjectID: hidden_project.ProjectID, data_source: data_source, CoCCode: 'MA-777')
        # Replaces the outer before block's datasource-wide grant with access to
        # only this one project, leaving hidden_project (and its CoC) invisible.
        collection.set_viewables({ projects: [visible_project.id] })
      end

      it 'excludes the invisible CoC code from the picker and skips the picker entirely' do
        get data_source_path(data_source)
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('MA-777')
        expect(response.body).not_to include('name="coc_code"')
        expect(response.body).to include('Visible Project')
        expect(response.body).not_to include('Hidden Project')
      end
    end
  end
end
