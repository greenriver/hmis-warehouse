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
end
