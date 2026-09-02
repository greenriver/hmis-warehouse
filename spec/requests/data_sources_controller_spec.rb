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

  describe 'GET #show' do
    it 'redirects unauthenticated users to sign in' do
      expect_unauthenticated_warehouse_request do
        get data_source_path(data_source)
      end
    end

    it 'denies users who cannot view projects, organizations, or imports' do
      sign_in user
      get data_source_path(data_source)
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
        create(:hud_project, data_source: data_source, OrganizationID: org_alpha.OrganizationID, ProjectName: 'Shelter MA-500', ProjectType: 0)
      end
      let!(:confidential_project_ma500) do
        create(:hud_project, data_source: data_source, OrganizationID: org_alpha.OrganizationID, ProjectName: 'Confidential Shelter MA-500', ProjectType: 0, confidential: true)
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
        create(:hud_project_coc, project: confidential_project_ma500, ProjectID: confidential_project_ma500.ProjectID, data_source: data_source, CoCCode: 'MA-500')
        create(:hud_project_coc, project: project_ma502, ProjectID: project_ma502.ProjectID, data_source: data_source, CoCCode: 'MA-502')
        create(:hud_project_coc, project: project_ma504, ProjectID: project_ma504.ProjectID, data_source: data_source, CoCCode: 'MA-504')
        create(:hud_project_coc, project: project_unknown, ProjectID: project_unknown.ProjectID, data_source: data_source, CoCCode: nil)
        create(:hud_project_coc, project: other_project, ProjectID: other_project.ProjectID, data_source: other_data_source, CoCCode: 'XX-999')
      end

      describe 'GET #show' do
        it 'shows the CoC cards grid instead of organizations' do
          get data_source_path(data_source)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Continuums of Care')
          expect(response.body).to include(data_source_with_coc_code_path(data_source, 'MA-500'))
          expect(response.body).to include(data_source_with_coc_code_path(data_source, 'MA-502'))
          expect(response.body).to include(data_source_with_coc_code_path(data_source, 'MA-504'))
          expect(response.body).not_to include('Alpha Housing')
          expect(response.body).not_to include('Beta Services')
        end

        it 'shows an Unassigned card linking to the unknown-CoC bucket when a ProjectCoC CoCCode is blank' do
          get data_source_path(data_source)
          expect(response.body).to include('Unassigned')
          expect(response.body).to include(data_source_with_coc_code_path(data_source, 'unknown'))
        end
      end

      describe 'GET #show via the bookmarkable CoC-code URL' do
        it 'shows only the requested CoC\'s organizations and projects' do
          get data_source_with_coc_code_path(data_source, 'MA-500')
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('MA-500')
          expect(response.body).to include('Alpha Housing')
          expect(response.body).to include('Shelter MA-500')
          expect(response.body).not_to include('RRH MA-502')
          expect(response.body).not_to include('TH MA-504')
          expect(response.body).not_to include('Unknown Coc Project')
          expect(response.body).not_to include('Other CoC Org')
          expect(response.body).not_to include('Foreign Project')
        end

        it 'renders the breadcrumb exactly once and skips the data source header cards' do
          get data_source_with_coc_code_path(data_source, 'MA-500')
          expect(response.body.scan('View Data Sources').size).to eq(1)
          expect(response.body).not_to include('Details & visibility')
        end

        it 'limits the Project Type filter to types actually present on the page' do
          get data_source_with_coc_code_path(data_source, 'MA-500')
          # Only project_ma500 (ProjectType: 0, "ES - Entry/Exit") is on this CoC's page -
          # the full 14-option HUD project type list must not appear.
          expect(response.body).to include('ES - Entry/Exit')
          expect(response.body).not_to include('>SSO<')
          expect(response.body).not_to include('>TH<')
        end

        it 'wires each project row with the search text the live filter matches against' do
          get data_source_with_coc_code_path(data_source, 'MA-500')
          expect(response.body).to include("data-table-filter-target='searchInput'")
          expect(response.body).to include("data-search-text='Shelter MA-500'")
        end

        it "renders each row's data-confidential attribute as the literal string 'true'/'false', not a bare/omitted boolean attribute" do
          # Haml's own attribute builder special-cases a literal Ruby true/false value in a
          # data: hash as an HTML boolean attribute (bare `data-confidential` for true, omitted
          # entirely for false) rather than the literal string the JS filter compares against -
          # the value must be pre-stringified in the view to avoid that.
          get data_source_with_coc_code_path(data_source, 'MA-500')
          expect(response.body).to include("data-confidential='true'")
          expect(response.body).to include("data-confidential='false'")
          expect(response.body).not_to match(/data-confidential(?!=)/)
        end

        it 'shows only projects with a blank CoCCode for the unknown bucket' do
          get data_source_with_coc_code_path(data_source, 'unknown')
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Unknown Coc Project')
          expect(response.body).to include('Beta Services')
          expect(response.body).not_to include('Shelter MA-500')
          expect(response.body).not_to include('RRH MA-502')
          expect(response.body).not_to include('TH MA-504')
        end

        it 'does not serve a CoC-scoped page for a data source the user cannot view' do
          get data_source_with_coc_code_path(other_data_source, 'XX-999')
          expect(response).to have_http_status(:not_found)
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
        expect(response.body).not_to include('Continuums of Care')
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

      it 'shows the CoC cards grid instead of organizations' do
        get data_source_path(data_source)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Continuums of Care')
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

      it 'excludes the invisible CoC code and skips the CoC picker entirely' do
        get data_source_path(data_source)
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('MA-777')
        expect(response.body).not_to include('Continuums of Care')
        expect(response.body).to include('Visible Project')
        expect(response.body).not_to include('Hidden Project')
      end
    end
  end

  describe 'with permission to edit the data source' do
    let(:edit_role) { create(:role, can_view_projects: true, can_edit_data_sources: true) }

    before do
      collection.set_viewables({ data_sources: [data_source.id] })
      setup_access_control(user, edit_role, collection)
      sign_in user
    end

    it 'shows Service Scanning and Personal ID/UUID as plain read-only rows on the Source Info card, not as More dropdown links' do
      data_source.update!(service_scannable: true, munged_personal_id: true)
      get data_source_path(data_source)
      expect(response.body).to include('Service Scanning Enabled?')
      expect(response.body).to include('Does the Personal ID column contain a UUID?')
      expect(response.body).not_to include('href="' + edit_data_source_path(data_source, anchor: 'grda_warehouse_data_source_service_scannable') + '"')
      expect(response.body).not_to include('href="' + edit_data_source_path(data_source, anchor: 'grda_warehouse_data_source_munged_personal_id') + '"')
    end

    it 'hides the More dropdown\'s import-gated items when the user cannot upload HUD zips' do
      get data_source_path(data_source)
      expect(response.body).to include('External HMIS Configuration')
      expect(response.body).not_to include('Import Cleanup Routines')
      expect(response.body).not_to include('Alert Configuration')
      expect(response.body).not_to include('Automate HMIS CSV Loads')
    end

    context 'and the user can also upload HUD zips' do
      let(:edit_role) { create(:role, can_view_projects: true, can_edit_data_sources: true, can_upload_hud_zips: true) }

      it "shows the More dropdown's import-gated items" do
        get data_source_path(data_source)
        expect(response.body).to include('Import Cleanup Routines')
        expect(response.body).to include('Alert Configuration')
        expect(response.body).to include('Automate HMIS CSV Loads')
      end
    end

    it 'renders the fields those anchors point at' do
      get edit_data_source_path(data_source)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="grda_warehouse_data_source_service_scannable"')
      expect(response.body).to include('id="grda_warehouse_data_source_munged_personal_id"')
    end
  end
end
