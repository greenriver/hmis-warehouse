###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'nokogiri'

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

  # The controller authorizes with before_actions. For a user with no rights, edit, update and
  # destroy 404 at the viewable_by load before the policy check runs, so the view-only context is
  # what proves the per-record edit and delete checks are wired up.
  describe 'authorization guards' do
    let(:update_params) { { grda_warehouse_data_source: { name: 'Renamed' } } }

    def expect_not_authorized
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    context 'for a user with no rights' do
      before { sign_in user }

      it 'denies show' do
        get data_source_path(data_source)
        expect_not_authorized
      end

      it 'does not find the data source to update' do
        patch data_source_path(data_source), params: update_params
        expect(response).to have_http_status(:not_found)
        expect(data_source.reload.name).not_to eq('Renamed')
      end
    end

    context 'for a user who can view the data source but has no data source rights' do
      before do
        collection.set_viewables({ data_sources: [data_source.id] })
        setup_access_control(user, create(:role, can_view_projects: true, can_edit_projects: true), collection)
        sign_in user
      end

      it 'allows show' do
        get data_source_path(data_source)
        expect(response).to have_http_status(:ok)
      end

      it 'denies edit, update, and destroy' do
        project = create(:hud_project, data_source: data_source, confidential: false)
        rename_with_nested_project_params = {
          grda_warehouse_data_source: {
            name: 'Renamed',
            projects_attributes: { '0' => { id: project.id, confidential: '1' } },
          },
        }

        get edit_data_source_path(data_source)
        expect_not_authorized

        patch data_source_path(data_source), params: rename_with_nested_project_params
        expect_not_authorized
        expect(data_source.reload.name).not_to eq('Renamed')
        expect(project.reload.confidential).to be(false)

        expect { delete data_source_path(data_source) }.not_to have_enqueued_job(DeleteItemJob)
        expect_not_authorized
      end
    end

    # Edit and delete rights don't reach a data source the user can't view: the record is loaded
    # through viewable_by, which requires can_view_projects.
    context 'for a user who can edit and delete the data source but not view projects' do
      before do
        collection.set_viewables({ data_sources: [data_source.id] })
        role = create(
          :role,
          can_view_imports: true,
          can_edit_data_sources: true,
          can_delete_data_sources: true,
        )
        setup_access_control(user, role, collection)
        sign_in user
      end

      # A not-found response drops the sign-in session, so sign in again before each request.
      it 'does not find the data source for edit, update, or destroy' do
        get edit_data_source_path(data_source)
        expect(response).to have_http_status(:not_found)

        sign_in user
        patch data_source_path(data_source), params: update_params
        expect(response).to have_http_status(:not_found)
        expect(data_source.reload.name).not_to eq('Renamed')

        sign_in user
        expect { delete data_source_path(data_source) }.not_to have_enqueued_job(DeleteItemJob)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'for a user who can edit the data source but not edit projects' do
      before do
        collection.set_viewables({ data_sources: [data_source.id] })
        setup_access_control(user, create(:role, can_view_projects: true, can_edit_data_sources: true), collection)
        sign_in user
      end

      it 'allows edit' do
        get edit_data_source_path(data_source)
        expect(response).to have_http_status(:ok)
      end

      it 'denies update' do
        patch data_source_path(data_source), params: update_params
        expect_not_authorized
        expect(data_source.reload.name).not_to eq('Renamed')
      end
    end
  end

  describe 'with permission to view the data source' do
    before do
      collection.set_viewables({ data_sources: [data_source.id] })
      setup_access_control(user, role, collection)
      sign_in user
      # Thresholds low enough that a handful of projects decides the CoC picker on
      # fragmentation and dominance alone.
      stub_const('GrdaWarehouse::DataSource::MIN_PROJECT_COUNT_FOR_COC_CHOICE', 2)
      stub_const('GrdaWarehouse::DataSource::MIN_FRAGMENT_COUNT_FOR_COC_CHOICE', 1)
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

    context 'with an organization contacts link' do
      let!(:org) { create(:hud_organization, data_source: data_source, OrganizationName: 'Contacts Link Org') }
      let!(:project) { create(:hud_project, data_source: data_source, OrganizationID: org.OrganizationID) }

      context 'when the role can edit organizations but cannot view imports' do
        let(:role) { create(:role, can_view_projects: true, can_edit_organizations: true) }

        it 'hides the link' do
          get data_source_path(data_source)

          expect(response.body).to include('Contacts Link Org')
          expect(response.body).not_to include(organization_contacts_path(org))
        end
      end

      context 'when the role can view imports on the data source' do
        let(:role) { create(:role, can_view_projects: true, can_view_imports: true) }

        it 'shows the link' do
          get data_source_path(data_source)

          expect(response.body).to include(organization_contacts_path(org))
        end
      end
    end

    context 'when one CoC holds the dominance share' do
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

    context 'when CoC codes are evenly split' do
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

  describe 'GET #index' do
    let(:destination_data_source) { create(:destination_data_source) }

    def create_linked_client(within_data_source)
      source_client = create(:grda_warehouse_hud_client, data_source: within_data_source)
      destination_client = source_client.dup
      destination_client.data_source = destination_data_source
      destination_client.save!
      create(:warehouse_client, destination_id: destination_client.id, source_id: source_client.id)
      source_client
    end

    def build_data_source_with_data(name:)
      ds = create(:source_data_source, name: name)
      org = create(:hud_organization, data_source: ds)
      project = create(:hud_project, data_source: ds, OrganizationID: org.OrganizationID)
      create_list(:hud_client, 2, data_source: ds)
      create(:hud_enrollment, data_source: ds, project: project, client: create_linked_client(ds), processed_as: nil)
      ds
    end

    # The first cell of each data source row links to that data source; the leading
    # warehouse-totals row has no link.
    def rendered_data_source_names(body)
      Nokogiri::HTML(body).css('tbody tr').filter_map { |row| row.at_css('td a')&.text&.strip }
    end

    context 'with counts to render' do
      let!(:ds_with_data) { create(:source_data_source, name: 'Alpha Vendor') }
      let!(:ds_without_data) { create(:source_data_source, name: 'Zeta Vendor') }
      let!(:org) { create(:hud_organization, data_source: ds_with_data) }
      let!(:project) { create(:hud_project, data_source: ds_with_data, OrganizationID: org.OrganizationID) }
      let!(:clients) { create_list(:hud_client, 2, data_source: ds_with_data) }
      let!(:eligible_enrollment) do
        create(:hud_enrollment, data_source: ds_with_data, project: project, client: create_linked_client(ds_with_data), processed_as: nil)
      end
      let!(:processed_enrollment) do
        create(:hud_enrollment, data_source: ds_with_data, project: project, client: create_linked_client(ds_with_data), processed_as: { 'a' => 1 })
      end

      before do
        collection.set_viewables({ data_sources: [ds_with_data.id, ds_without_data.id] })
        setup_access_control(user, role, collection)
        sign_in user
      end

      it 'shows accurate client, project, and unprocessed-enrollment counts per data source, including a data source with none' do
        get data_sources_path
        expect(response).to have_http_status(:ok)

        doc = Nokogiri::HTML(response.body)
        rows = doc.css('tbody tr')

        row_with_data = rows.find { |r| r.at_css('td a')&.text == 'Alpha Vendor' }
        cells = row_with_data.css('td')
        # 2 explicit clients plus the 2 source clients created by create_linked_client
        # for the eligible/processed enrollments below.
        expect(cells[2].text.strip).to eq('4')
        expect(cells[3].text.strip).to eq('1')
        expect(row_with_data.text).to include('Enrollments remaining to process: 1')

        row_without_data = rows.find { |r| r.at_css('td a')&.text == 'Zeta Vendor' }
        cells = row_without_data.css('td')
        expect(cells[2].text.strip).to eq('0')
        expect(cells[3].text.strip).to eq('0')
        expect(row_without_data.text).not_to include('Enrollments remaining to process')
      end

      it 'shows the stalled-import label only for a data source whose most recent import is stale' do
        ds_with_data.update!(last_imported_at: 30.hours.ago)
        create(:grda_warehouse_hmis_import_config, data_source: ds_with_data, file_count: 1)
        create(:grda_warehouse_upload, data_source: ds_with_data, user: User.system_user, percent_complete: 100, completed_at: 30.hours.ago)

        # Zeta has imported too, so its row reaches the same stall check Alpha's does and the
        # label's absence there is attributable to the stall rule rather than to the outer
        # `last_imported_at.present?` gate in the view.
        ds_without_data.update!(last_imported_at: 2.hours.ago)
        create(:grda_warehouse_hmis_import_config, data_source: ds_without_data, file_count: 1)
        create(:grda_warehouse_upload, data_source: ds_without_data, user: User.system_user, percent_complete: 100, completed_at: 2.hours.ago)

        get data_sources_path
        expect(response).to have_http_status(:ok)

        doc = Nokogiri::HTML(response.body)
        rows = doc.css('tbody tr')

        row_with_data = rows.find { |r| r.at_css('td a')&.text == 'Alpha Vendor' }
        expect(row_with_data.text).to include('same file since:')

        row_without_data = rows.find { |r| r.at_css('td a')&.text == 'Zeta Vendor' }
        expect(row_without_data.text).not_to include('same file since:')
      end
    end

    context 'query efficiency' do
      it 'runs a bounded number of queries regardless of how many data sources are on the page' do
        count_queries = lambda do |&block|
          count = 0
          callback = ->(*) { count += 1 }
          ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)
          count
        end

        small_batch = Array.new(3) { |i| build_data_source_with_data(name: "Small Vendor #{i}") }
        collection.set_viewables({ data_sources: small_batch.map(&:id) })
        setup_access_control(user, role, collection)
        sign_in user

        # Warm up one-time schema-cache/connection-setup queries so they don't confound
        # the small-vs-large comparison below.
        get data_sources_path
        expect(response).to have_http_status(:ok)

        small_queries = count_queries.call { get data_sources_path }
        expect(rendered_data_source_names(response.body)).to match_array(small_batch.map(&:name))

        large_batch = small_batch + Array.new(9) { |i| build_data_source_with_data(name: "Large Vendor #{i}") }
        collection.set_viewables({ data_sources: large_batch.map(&:id) })
        # This comparison only holds if every data source in large_batch lands on page 1;
        # otherwise large_queries would undercount and the assertion below would pass for
        # the wrong reason.
        expect(large_batch.size).to be <= Pagy::DEFAULT[:items]

        large_queries = count_queries.call { get data_sources_path }
        # The query comparison below is only meaningful if the nine additional data sources
        # actually rendered; a page that kept showing three rows would match on query count
        # while exercising none of the added load.
        expect(rendered_data_source_names(response.body)).to match_array(large_batch.map(&:name))

        # A regression to the old per-row query pattern (client/project/unprocessed-enrollment
        # counts each queried once per row) would make large_queries scale with data source
        # count (9 more data sources here); a small constant tolerance accommodates incidental
        # preload-boundary variance without masking that regression.
        expect(large_queries).to be_within(5).of(small_queries)
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

  describe 'PATCH #update for an Open Path HMIS data source' do
    let(:role) { create(:role, can_view_projects: true, can_edit_projects: true, can_edit_data_sources: true) }
    let(:hmis_data_source) { create(:hmis_primary_data_source) }

    before do
      collection.set_viewables({ data_sources: [hmis_data_source.id] })
      setup_access_control(user, role, collection)
      sign_in user
    end

    it 'stores the go-live time in the app time zone' do
      patch data_source_path(hmis_data_source), params: { grda_warehouse_data_source: { hmis_go_live_at: 'Oct 1, 2026 6:00 AM' } }

      expect(hmis_data_source.reload.hmis_go_live_at).to eq(Time.zone.local(2026, 10, 1, 6, 0))
    end

    it 'clears the go-live time when the field is blank' do
      hmis_data_source.update!(hmis_go_live_at: 1.day.from_now)

      patch data_source_path(hmis_data_source), params: { grda_warehouse_data_source: { hmis_go_live_at: '' } }

      expect(hmis_data_source.reload.hmis_go_live_at).to be_nil
    end

    it 'renders the saved go-live time as a two-digit 12-hour clock beside the calendar on the edit form' do
      hmis_data_source.update!(hmis_go_live_at: Time.zone.local(2026, 10, 1, 6, 30))

      get edit_data_source_path(hmis_data_source)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="Oct 1, 2026 06:30 AM"')
      expect(response.body).to include('&quot;sideBySide&quot;:true')
    end
  end
  describe 'client retention override' do
    let(:role) { create(:role, can_view_projects: true, can_edit_projects: true, can_edit_data_sources: true) }
    let(:data_source) { create(:source_data_source) }

    def configure_global_retention(years)
      GrdaWarehouse::Config.first_or_create.update!(client_retention_years: years)
      GrdaWarehouse::Config.invalidate_cache
    end

    before do
      collection.set_viewables({ data_sources: [data_source.id] })
      setup_access_control(user, role, collection)
      sign_in user
    end

    after { GrdaWarehouse::Config.invalidate_cache }

    context 'when the global window is set' do
      before { configure_global_retention(7) }

      it 'offers the override select with the global value named as the fallback' do
        get edit_data_source_path(data_source)

        select = Nokogiri::HTML(response.body).at_css("select[name='grda_warehouse_data_source[client_retention_years]']")
        expect(select).not_to be_nil
        expect(select.css('option').map(&:text)).to include('Use global setting (7 years)', '10 years')
      end

      it 'saves the override' do
        patch data_source_path(data_source), params: { grda_warehouse_data_source: { client_retention_years: 10 } }

        expect(data_source.reload.client_retention_years).to eq(10)
      end

      it 'reports the global window on the show page when no override is set' do
        get data_source_path(data_source)

        expect(response.body).to include('Global setting (7 years)')
      end
    end

    context 'when global retention is disabled' do
      before { configure_global_retention(nil) }

      it 'does not render the override select' do
        get edit_data_source_path(data_source)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('grda_warehouse_data_source[client_retention_years]')
      end

      it 'ignores a posted override so a stale form cannot set one' do
        patch data_source_path(data_source), params: { grda_warehouse_data_source: { client_retention_years: 10, name: 'Renamed' } }

        expect(data_source.reload.name).to eq('Renamed')
        expect(data_source.client_retention_years).to be_nil
      end
    end
  end

  describe 'writes to a data source the user can only view through one project' do
    let(:editor_role) { create(:role, can_view_projects: true, can_edit_projects: true, can_edit_data_sources: true, can_delete_data_sources: true) }
    let(:viewer_role) { create(:role, can_view_projects: true) }
    let(:editable_data_source) { create(:source_data_source) }
    let(:edit_collection) { create(:collection) }
    let(:view_collection) { create(:collection) }
    let!(:viewed_org) { create(:hud_organization, data_source: data_source) }
    let!(:viewed_project) { create(:hud_project, data_source: data_source, OrganizationID: viewed_org.OrganizationID) }
    let!(:unseen_project) { create(:hud_project, data_source: data_source, OrganizationID: viewed_org.OrganizationID, confidential: false) }

    before do
      edit_collection.set_viewables({ data_sources: [editable_data_source.id] })
      view_collection.set_viewables({ projects: [viewed_project.id] })
      setup_access_control(user, editor_role, edit_collection)
      setup_access_control(user, viewer_role, view_collection)
      sign_in user
    end

    it 'still updates the data source the role covers' do
      patch data_source_path(editable_data_source), params: { grda_warehouse_data_source: { name: 'Renamed' } }
      expect(response).to redirect_to(data_source_path(editable_data_source))
      expect(editable_data_source.reload.name).to eq('Renamed')
    end

    # The role grants can_edit_data_sources, so only the per-record edit and delete checks stop
    # these writes to a data source the role doesn't cover.
    it 'does not update or delete the data source the user can only view' do
      rename_with_nested_project_params = {
        grda_warehouse_data_source: {
          name: 'Renamed',
          projects_attributes: { '0' => { id: unseen_project.id, confidential: '1' } },
        },
      }

      patch data_source_path(data_source), params: rename_with_nested_project_params
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
      expect(data_source.reload.name).not_to eq('Renamed')
      expect(unseen_project.reload.confidential).to be(false)

      expect { delete data_source_path(data_source) }.not_to have_enqueued_job(DeleteItemJob)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it 'shows the Edit button only on the data source the role covers' do
      get data_source_path(data_source)
      expect(Nokogiri::HTML(response.body).css("a[href='#{edit_data_source_path(data_source)}']")).to be_empty

      get data_source_path(editable_data_source)
      expect(Nokogiri::HTML(response.body).css("a[href='#{edit_data_source_path(editable_data_source)}']").size).to eq(1)
    end

    it 'shows the index delete button only on the data source the role covers' do
      get data_sources_path
      delete_links = Nokogiri::HTML(response.body).css("a[data-method='delete'][href^='/data_sources/']").map { |a| a['href'] }
      expect(delete_links).to contain_exactly(data_source_path(editable_data_source))
    end
  end

  # Building through viewable_by would copy a single viewable id onto the new record, so create
  # must build from the bare model.
  describe 'POST #create by a user who can view exactly one data source' do
    before do
      collection.set_viewables({ data_sources: [data_source.id] })
      setup_access_control(user, create(:role, can_view_projects: true, can_edit_data_sources: true), collection)
      sign_in user
    end

    it 'creates a new data source' do
      create_params = { grda_warehouse_data_source: { name: 'New Source', short_name: 'NEW' } }

      expect { post data_sources_path, params: create_params }.
        to change(GrdaWarehouse::DataSource, :count).by(1)
      expect(response).to redirect_to(data_sources_path)
    end
  end

  describe 'DELETE #destroy' do
    let(:edit_only_role) { create(:role, can_view_projects: true, can_edit_data_sources: true) }
    let(:delete_role) { create(:role, can_view_projects: true, can_edit_data_sources: true, can_delete_data_sources: true) }

    before do
      collection.set_viewables({ data_sources: [data_source.id] })
      sign_in user
    end

    it 'refuses an editor without the delete permission' do
      setup_access_control(user, edit_only_role, collection)
      expect { delete data_source_path(data_source) }.not_to have_enqueued_job(DeleteItemJob)
      expect(response).to redirect_to(root_path)
    end

    it 'queues the delete for a user with the delete permission' do
      setup_access_control(user, delete_role, collection)
      expect { delete data_source_path(data_source) }.
        to have_enqueued_job(DeleteItemJob).with(item_id: data_source.id, item_class: 'GrdaWarehouse::DataSource')
    end

    context 'with the delete permission only in another collection' do
      let(:deletable_data_source) { create(:source_data_source) }
      let(:delete_collection) { create(:collection) }

      before do
        delete_collection.set_viewables({ data_sources: [deletable_data_source.id] })
        setup_access_control(user, create(:role, can_view_projects: true, can_delete_data_sources: true), delete_collection)
        setup_access_control(user, edit_only_role, collection)
      end

      it 'does not queue the delete of a data source the user can only edit' do
        expect { delete data_source_path(data_source) }.not_to have_enqueued_job(DeleteItemJob)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'GET #show query efficiency' do
    let!(:org) { create(:hud_organization, data_source: data_source) }

    def create_projects(count, prefix)
      Array.new(count) { |i| create(:hud_project, data_source: data_source, OrganizationID: org.OrganizationID, ProjectName: "#{prefix} Project #{i}") }
    end

    def count_queries(&block)
      count = 0
      ActiveSupport::Notifications.subscribed(->(*) { count += 1 }, 'sql.active_record', &block)
      count
    end

    def rendered_project_names(body)
      Nokogiri::HTML(body).css('.project__name a').map { |a| a.text.strip }
    end

    before do
      collection.set_viewables({ data_sources: [data_source.id] })
      setup_access_control(user, role, collection)
      sign_in user
    end

    it 'runs a bounded number of queries regardless of how many projects are listed' do
      small_batch = create_projects(2, 'Small')
      # Warm up one-time schema-cache queries so they don't skew the comparison.
      get data_source_path(data_source)
      small_queries = count_queries { get data_source_path(data_source) }
      expect(rendered_project_names(response.body)).to match_array(small_batch.map(&:ProjectName))

      large_batch = small_batch + create_projects(10, 'Large')
      large_queries = count_queries { get data_source_path(data_source) }
      expect(rendered_project_names(response.body)).to match_array(large_batch.map(&:ProjectName))

      # Per-project permission lookups add at least one query per project (10 more here).
      expect(large_queries).to be_within(5).of(small_queries)
    end
  end

  describe 'confidential project names with edit rights in another collection' do
    let(:editor_role) { create(:role, can_view_projects: true, can_edit_projects: true) }
    let(:viewer_role) { create(:role, can_view_projects: true) }
    let(:other_collection) { create(:collection) }
    let!(:org) { create(:hud_organization, data_source: data_source) }
    let!(:confidential_project) do
      create(:hud_project, data_source: data_source, OrganizationID: org.OrganizationID, ProjectName: 'Hidden Shelter Name', confidential: true)
    end

    before do
      collection.set_viewables({ data_sources: [data_source.id] })
      other_collection.set_viewables({ data_sources: [create(:source_data_source).id] })
      setup_access_control(user, viewer_role, collection)
      setup_access_control(user, editor_role, other_collection)
      sign_in user
    end

    it 'masks the confidential project name' do
      get data_source_path(data_source)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Hidden Shelter Name')
      expect(response.body).to include(GrdaWarehouse::Hud::Project.confidential_project_name)
    end

    it 'shows the name when the user can edit that project' do
      project_edit_collection = create(:collection)
      project_edit_collection.set_viewables({ projects: [confidential_project.id] })
      setup_access_control(user, editor_role, project_edit_collection)

      get data_source_path(data_source)
      expect(response.body).to include('Hidden Shelter Name')
    end
  end

  describe 'confidential organization names' do
    let(:viewer_role) { create(:role, can_view_projects: true) }
    let(:org_editor_role) { create(:role, can_view_projects: true, can_edit_organizations: true) }
    let(:other_collection) { create(:collection) }
    let!(:confidential_org) { create(:hud_organization, data_source: data_source, OrganizationName: 'Hidden Agency Name', confidential: true) }
    let!(:project) { create(:hud_project, data_source: data_source, OrganizationID: confidential_org.OrganizationID) }

    before do
      collection.set_viewables({ data_sources: [data_source.id] })
      setup_access_control(user, viewer_role, collection)
      sign_in user
    end

    it 'masks the name when the user can edit organizations only in another collection' do
      other_collection.set_viewables({ data_sources: [create(:source_data_source).id] })
      setup_access_control(user, org_editor_role, other_collection)

      get data_source_path(data_source)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Hidden Agency Name')
    end

    it 'shows the name when the user can edit that organization' do
      other_collection.set_viewables({ organizations: [confidential_org.id] })
      setup_access_control(user, org_editor_role, other_collection)

      get data_source_path(data_source)
      expect(response.body).to include('Hidden Agency Name')
    end
  end

  describe 'PATCH #update with the project edit permission only on another collection' do
    let(:project) { create(:hud_project, data_source: data_source, confidential: false) }

    before do
      collection.set_viewables({ data_sources: [data_source.id] })
      setup_access_control(user, create(:role, can_view_projects: true, can_edit_data_sources: true), collection)
      setup_access_control(user, create(:role, can_view_projects: true, can_edit_projects: true), create(:collection))
      sign_in user
    end

    it 'does not update the data source or its projects' do
      patch data_source_path(data_source), params: {
        grda_warehouse_data_source: {
          name: 'Renamed',
          projects_attributes: [{ id: project.id, confidential: '1' }],
        },
      }

      expect(response).to redirect_to(root_path)
      expect(data_source.reload.name).not_to eq('Renamed')
      expect(project.reload.confidential).to be(false)
    end
  end
end
