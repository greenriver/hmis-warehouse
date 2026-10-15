###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::CollectionsController, type: :request do
  let!(:user) { create(:user) }
  let!(:admin) { create(:user) }
  let!(:admin_role) do
    create(:admin_role,
           can_edit_collections: true)
  end

  let!(:project_coc) { create(:hud_project_coc, CoCCode: 'XX-500') }
  let!(:project_coc_2) { create :hud_project_coc }
  let!(:data_source) { create :data_source_fixed_id }
  let!(:organization) { create :grda_warehouse_hud_organization }
  let!(:project_group) { create :project_group }
  let!(:project_group_2) { create :project_group }
  let!(:project) { create :grda_warehouse_hud_project, organization: organization }
  let!(:report) { create :core_demographics_report }
  let!(:cohort) { create :cohort }
  let!(:supplemental_data_set) { create :hmis_supplemental_data_set, data_source: data_source }

  let!(:project_collection) { create :collection }
  let!(:legacy_project_collection) { create(:collection, :skip_validate, collection_type: nil) }

  before(:each) do
    sign_in admin
    admin.legacy_roles << admin_role
  end

  def run_entity_tests(collection:, coc_codes: [], data_sources: [], organizations: [], projects: [], project_groups: [], project_access_groups: [], reports: [], cohorts: [], supplemental_data_sets: [])
    collection.reload
    expect(collection.coc_code_ids.map(&:to_s)).to eq(coc_codes.map(&:to_s))
    expect(collection.data_source_ids.map(&:to_s)).to eq(data_sources.map(&:to_s))
    expect(collection.organization_ids.map(&:to_s)).to eq(organizations.map(&:to_s))
    expect(collection.project_ids.map(&:to_s)).to eq(projects.map(&:to_s))
    expect(collection.project_group_ids.map(&:to_s)).to eq(project_groups.map(&:to_s))
    expect(collection.project_access_group_ids.map(&:to_s)).to eq(project_access_groups.map(&:to_s))
    expect(collection.report_ids.map(&:to_s)).to eq(reports.map(&:to_s))
    expect(collection.cohort_ids.map(&:to_s)).to eq(cohorts.map(&:to_s))
    expect(collection.supplemental_data_sets.map(&:id).map(&:to_s)).to eq(supplemental_data_sets.map(&:to_s))
  end

  # Creating current collection #create
  describe 'POST #create' do
    let(:collection_params) do
      {
        collection: {
          name: 'New Collection',
          description: 'New Collection Description',
          collection_type: 'Projects',
        },
      }
    end

    it 'creates a new collection' do
      expect do
        post admin_collections_path, params: collection_params
      end.to change(Collection, :count).by(1)
    end
  end

  describe 'GET #edit' do
    it 'links back to the collection show page' do
      get edit_admin_collection_path(project_collection)

      links = Nokogiri::HTML(response.body).css(%(a[href="#{admin_collection_path(project_collection)}"]))
      expect(links.map { |link| link.text.squish }).to include("« #{project_collection.name}")
    end
  end

  describe 'PUT update' do
    let(:viewable_params) do
      {
        collection: {
          coc_codes: [project_coc.lookup_coc.id],
          data_sources: [data_source.id],
          organizations: [organization.id],
          projects: [project.id],
          project_access_groups: [project_group.id],
          reports: [report.id],
          cohorts: [cohort.id],
          project_groups: [project_group_2.id],
          supplemental_data_sets: [supplemental_data_set.id],
        },
      }
    end

    it 'Updates collection name & description #update' do
      # Set some base vieawables. We want to make sure these don't change.
      project_collection.set_viewables(
        {
          data_sources: [data_source.id],
          organizations: [organization.id],
          coc_codes: [project_coc.lookup_coc.id],
          projects: [project.id],
          project_groups: [project_group_2.id],
          project_access_groups: [project_group.id],
          reports: [report.id],
          cohorts: [cohort.id],
          supplemental_data_sets: [supplemental_data_set.id],
        },
      )
      project_collection.save!
      # make sure the viewables exist
      run_entity_tests(
        collection: project_collection,
        coc_codes: [project_coc.lookup_coc.id],
        data_sources: [data_source.id],
        organizations: [organization.id],
        projects: [project.id],
        project_groups: [project_group_2.id],
        project_access_groups: [project_group.id],
        reports: [report.id],
        cohorts: [cohort.id],
        supplemental_data_sets: [supplemental_data_set.id],
      )

      patch admin_collection_path(project_collection), params: {
        collection: {
          name: 'Updated Name',
          description: 'Updated Description',
        },
      }
      expect(project_collection.reload.name).to eq('Updated Name')
      expect(project_collection.reload.description).to eq('Updated Description')

      # make sure the viewables are not changed
      run_entity_tests(
        collection: project_collection,
        coc_codes: [project_coc.lookup_coc.id],
        data_sources: [data_source.id],
        organizations: [organization.id],
        projects: [project.id],
        project_groups: [project_group_2.id],
        project_access_groups: [project_group.id],
        reports: [report.id],
        cohorts: [cohort.id],
        supplemental_data_sets: [supplemental_data_set.id],
      )
    end

    it 'Updating legacy collection name & description #update' do
      patch admin_collection_path(legacy_project_collection), params: {
        collection: {
          name: 'Updated Legacy Name',
          description: 'Updated Legacy Description',
        },
      }
      expect(legacy_project_collection.reload.name).to eq('Updated Legacy Name')
      expect(legacy_project_collection.reload.description).to eq('Updated Legacy Description')
    end

    it 'Updating legacy collection viewables #update' do
      patch admin_collection_path(legacy_project_collection), params: viewable_params
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: viewable_params[:collection][:coc_codes],
        data_sources: viewable_params[:collection][:data_sources],
        organizations: viewable_params[:collection][:organizations],
        projects: viewable_params[:collection][:projects],
        project_groups: viewable_params[:collection][:project_groups],
        project_access_groups: viewable_params[:collection][:project_access_groups],
        reports: viewable_params[:collection][:reports],
        cohorts: viewable_params[:collection][:cohorts],
        supplemental_data_sets: viewable_params[:collection][:supplemental_data_sets],
      )
    end
  end

  describe 'GET #entities' do
    it 'renders successfully for valid entity types' do
      Admin::Collections::CONFIG.keys.each do |entity_type|
        get entities_admin_collection_path(project_collection, entities: entity_type)
        expect(response).to be_successful
      end
    end

    it 'raises ArgumentError for invalid entity type' do
      expect do
        get entities_admin_collection_path(project_collection, entities: :invalid_type)
      end.to raise_error(ArgumentError, /Unknown entity type/)
    end

    def entity_rows
      Nokogiri::HTML(response.body).css('table.collections tbody tr').to_h do |tr|
        cells = tr.css('td').map { |td| td.text.strip }
        [cells[1], cells[2..]]
      end
    end

    def queries_for_entities_page(entities)
      count = 0
      counter = ->(*, payload) { count += 1 unless payload[:name].in?(['SCHEMA', 'TRANSACTION']) || payload[:cached] }
      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
        get entities_admin_collection_path(project_collection, entities: entities)
      end
      count
    end

    def soft_delete(record)
      record.update_columns(DateDeleted: Time.current)
    end

    describe 'organizations' do
      def add_organization_with_project
        org = create(:grda_warehouse_hud_organization)
        create(:grda_warehouse_hud_project, organization: org)
      end

      it 'counts projects per organization' do
        organization.update!(OrganizationName: 'Two Project Org')
        create(:grda_warehouse_hud_project, organization: organization)
        other_org = create(:grda_warehouse_hud_organization, OrganizationName: 'One Project Org')
        create(:grda_warehouse_hud_project, organization: other_org)

        get entities_admin_collection_path(project_collection, entities: :organizations)

        expect(entity_rows).to eq(
          'Two Project Org' => ['Green River', '2'],
          'One Project Org' => ['Green River', '1'],
        )
      end

      it 'counts projects separately for organizations sharing an OrganizationID across data sources' do
        organization.update!(OrganizationName: 'Home Org')
        other_data_source = create(:grda_warehouse_data_source, name: 'Other Source')
        create(
          :grda_warehouse_hud_organization,
          data_source_id: other_data_source.id,
          OrganizationID: organization.OrganizationID,
          OrganizationName: 'Shared ID Org',
        )
        create_list(:grda_warehouse_hud_project, 2, data_source_id: other_data_source.id, OrganizationID: organization.OrganizationID)

        get entities_admin_collection_path(project_collection, entities: :organizations)

        expect(entity_rows).to eq(
          'Home Org' => ['Green River', '1'],
          'Shared ID Org' => ['Other Source', '2'],
        )
      end

      it 'excludes organizations whose data source is deleted' do
        organization.update!(OrganizationName: 'Live Org')
        deleted_data_source = create(:grda_warehouse_data_source)
        create(:grda_warehouse_hud_organization, data_source_id: deleted_data_source.id, OrganizationName: 'Orphan Org')
        deleted_data_source.destroy!

        get entities_admin_collection_path(project_collection, entities: :organizations)

        expect(entity_rows.keys).to contain_exactly('Live Org')
      end

      it 'runs the same number of queries regardless of organization count' do
        queries_for_entities_page(:organizations) # warm per-process caches
        baseline = queries_for_entities_page(:organizations)
        3.times { add_organization_with_project }

        expect(queries_for_entities_page(:organizations)).to eq(baseline)
      end
    end

    describe 'data sources' do
      let!(:other_data_source) { create(:grda_warehouse_data_source, name: 'Other Source', source_type: :sftp) }

      before do
        project_coc.data_source.update!(name: 'Vendor A')
        project_coc_2.data_source.update!(name: 'Vendor B')
      end

      it 'shows client count, project count, and last import per data source, ignoring deleted rows' do
        create(:grda_warehouse_hud_client, data_source: data_source)
        soft_delete(create(:grda_warehouse_hud_client, data_source: data_source))
        create_list(:grda_warehouse_hud_client, 3, data_source: other_data_source)
        create(:grda_warehouse_hud_project)
        soft_delete(create(:grda_warehouse_hud_project))
        create(:grda_warehouse_hud_project, data_source_id: other_data_source.id)
        last_import = Time.zone.local(2026, 3, 2, 10)
        GrdaWarehouse::ImportLog.create!(data_source_id: data_source.id, completed_at: last_import - 1.day)
        GrdaWarehouse::ImportLog.create!(data_source_id: data_source.id, completed_at: last_import)

        get entities_admin_collection_path(project_collection, entities: :data_sources)

        expect(entity_rows).to eq(
          'Green River' => ['1', '2', last_import.localtime.to_s],
          'Other Source' => ['3', '1', ''],
          'Vendor A' => ['0', '0', ''],
          'Vendor B' => ['0', '0', ''],
        )
      end

      def add_data_source_with_rows
        source = create(:grda_warehouse_data_source, source_type: :sftp)
        create(:grda_warehouse_hud_client, data_source: source)
        create(:grda_warehouse_hud_project, data_source_id: source.id)
        GrdaWarehouse::ImportLog.create!(data_source_id: source.id, completed_at: Time.current)
      end

      it 'runs the same number of queries regardless of data source count' do
        add_data_source_with_rows # baseline needs every row type so batched preloads run on both sides
        queries_for_entities_page(:data_sources) # warm per-process caches
        baseline = queries_for_entities_page(:data_sources)
        3.times { add_data_source_with_rows }

        expect(queries_for_entities_page(:data_sources)).to eq(baseline)
      end
    end

    [:project_groups, :project_access_groups].each do |entities|
      describe entities.to_s do
        it 'counts projects per group, ignoring deleted projects' do
          project_group.update!(name: 'Two Project Group')
          project_group.projects << project
          project_group.projects << create(:grda_warehouse_hud_project)
          project_group_2.update!(name: 'One Project Group')
          project_group_2.projects << create(:grda_warehouse_hud_project)
          deleted_project = create(:grda_warehouse_hud_project)
          project_group_2.projects << deleted_project
          soft_delete(deleted_project)

          get entities_admin_collection_path(project_collection, entities: entities)

          expect(entity_rows).to eq(
            'Two Project Group' => ['2'],
            'One Project Group' => ['1'],
          )
        end

        it 'runs the same number of queries regardless of group count' do
          queries_for_entities_page(entities) # warm per-process caches
          baseline = queries_for_entities_page(entities)
          3.times { create(:project_group).projects << create(:grda_warehouse_hud_project) }

          expect(queries_for_entities_page(entities)).to eq(baseline)
        end
      end
    end

    describe 'CoC codes' do
      # CoC code lookups are seeded from HudHelper.util.cocs before the suite runs.
      def add_project_to_coc(coc_code, project: create(:grda_warehouse_hud_project))
        create(:hud_project_coc, CoCCode: coc_code, data_source_id: project.data_source_id, ProjectID: project.ProjectID)
      end

      it 'shows the official name and counts projects per CoC, ignoring deleted projects' do
        add_project_to_coc('XX-500')
        add_project_to_coc('XX-500', project: project)
        add_project_to_coc('XX-501')
        deleted_project = create(:grda_warehouse_hud_project)
        add_project_to_coc('XX-501', project: deleted_project)
        soft_delete(deleted_project)

        get entities_admin_collection_path(project_collection, entities: :coc_codes)

        expect(entity_rows).to eq(
          'XX-500' => ['Test CoC', '2'],
          'XX-501' => ['2nd Test CoC', '1'],
          project_coc_2.CoCCode => [project_coc_2.lookup_coc.official_name, '0'],
        )
      end

      it 'runs the same number of queries regardless of CoC count' do
        queries_for_entities_page(:coc_codes) # warm per-process caches
        baseline = queries_for_entities_page(:coc_codes)
        ['XX-502', 'XX-518', 'AA-000'].each { |coc_code| add_project_to_coc(coc_code) }

        expect(queries_for_entities_page(:coc_codes)).to eq(baseline)
      end
    end
  end

  describe 'PUT bulk_entities' do
    let!(:data_sources) do
      GrdaWarehouse::DataSource.
        source.
        order(:name).
        map { |ds| [ds.id.to_s, '0'] }.to_h
    end
    let!(:project_access_groups) do
      GrdaWarehouse::ProjectAccessGroup.
        order(:name).
        map { |pg| [pg.id.to_s, '0'] }.to_h
    end
    let!(:coc_codes) do
      GrdaWarehouse::Lookups::CocCode.
        joins(:project_cocs).
        distinct.
        order(:coc_code).
        pluck(:id, :coc_code).
        compact.
        map { |id, _| [id.to_s, '0'] }.to_h
    end
    let!(:project_groups) do
      GrdaWarehouse::ProjectGroup.
        order(:name).
        map { |pg| [pg.id.to_s, '0'] }.to_h
    end
    let!(:cohorts) do
      GrdaWarehouse::Cohort.
        active.
        order(:name).
        map { |c| [c.id.to_s, '0'] }.to_h
    end
    let!(:organizations) do
      GrdaWarehouse::Hud::Organization.
        order(:name).
        map { |org| [org.id.to_s, '0'] }.to_h
    end
    let!(:projects) do
      GrdaWarehouse::Hud::Project.
        order(:name).
        map { |p| [p.id.to_s, '0'] }.to_h
    end
    let!(:reports) do
      GrdaWarehouse::WarehouseReports::ReportDefinition.
        enabled.
        order(:report_group, :name).
        map { |r| [r.id.to_s, '0'] }.to_h
    end
    let!(:supplemental_data_sets) do
      HmisSupplemental::DataSet.
        order(:name, :id).
        map { |ds| [ds.id.to_s, '0'] }.to_h
    end
    let!(:bulk_entities_params) do
      {
        collection: {
          coc_codes: coc_codes,
          data_sources: data_sources,
          organizations: organizations,
          projects: projects,
          project_access_groups: project_groups,
          reports: reports,
          cohorts: cohorts,
          project_groups: project_groups,
          supplemental_data_sets: supplemental_data_sets,
        },
      }
    end

    it 'Updating current collection viewables #bulk_entities' do
      expected = {}

      coc_codes[project_coc.lookup_coc.id.to_s] = '1'
      data_sources[data_source.id.to_s] = '1'
      organizations[organization.id.to_s] = '1'
      projects[project.id.to_s] = '1'
      project_groups[project_group.id.to_s] = '1'
      project_access_groups[project_group.id.to_s] = '1'
      reports[report.id.to_s] = '1'
      cohorts[cohort.id.to_s] = '1'
      supplemental_data_sets[supplemental_data_set.id.to_s] = '1'

      # Each entity should only be updating their corresponding viewable on the collection and should not be changing the values of the other entities
      ['coc_codes', 'data_sources', 'organizations', 'projects', 'project_groups', 'project_access_groups', 'reports', 'cohorts', 'supplemental_data_sets'].each do |entity|
        # Set the expected value for this specific entity. Any entity that had previously been set will remain, but all future entities in the loop will still be expected to have a [] value.
        # This will help ensure that only the expected entity is being updated.
        expected[entity.to_sym] = bulk_entities_params[:collection][entity.to_sym].keys.select { |k| bulk_entities_params[:collection][entity.to_sym][k] == '1' }
        # Update the entity on the collection
        patch bulk_entities_admin_collection_path(project_collection), params: bulk_entities_params.merge(entities: entity)
        # Verify the updated collection
        aggregate_failures do
          run_entity_tests(
            collection: project_collection,
            coc_codes: expected[:coc_codes] || [],
            data_sources: expected[:data_sources] || [],
            organizations: expected[:organizations] || [],
            projects: expected[:projects] || [],
            project_groups: expected[:project_groups] || [],
            project_access_groups: expected[:project_access_groups] || [],
            reports: expected[:reports] || [],
            cohorts: expected[:cohorts] || [],
            supplemental_data_sets: expected[:supplemental_data_sets] || [],
          )
        end
      end

      # We are now going to remove each entity and ensure that only the entity being removed is affected
      coc_codes[project_coc.lookup_coc.id.to_s] = '0'
      data_sources[data_source.id.to_s] = '0'
      organizations[organization.id.to_s] = '0'
      projects[project.id.to_s] = '0'
      project_groups[project_group.id.to_s] = '0'
      project_access_groups[project_group.id.to_s] = '0'
      reports[report.id.to_s] = '0'
      cohorts[cohort.id.to_s] = '0'
      supplemental_data_sets[supplemental_data_set.id.to_s] = '0'

      ['coc_codes', 'data_sources', 'organizations', 'projects', 'project_groups', 'project_access_groups', 'reports', 'cohorts', 'supplemental_data_sets'].each do |entity|
        # Set the expected value for this specific entity to []. Any entity that had previously been set will also be an empty array, but all future entities in the
        # loop will still be expected to have a previously set value. This will help ensure that only the expected entity is being updated.
        expected[entity.to_sym] = []
        # Update the entity on the collection
        patch bulk_entities_admin_collection_path(project_collection), params: bulk_entities_params.merge(entities: entity)
        # Verify the updated collection
        aggregate_failures do
          run_entity_tests(
            collection: project_collection,
            coc_codes: expected[:coc_codes] || [],
            data_sources: expected[:data_sources] || [],
            organizations: expected[:organizations] || [],
            projects: expected[:projects] || [],
            project_groups: expected[:project_groups] || [],
            project_access_groups: expected[:project_access_groups] || [],
            reports: expected[:reports] || [],
            cohorts: expected[:cohorts] || [],
            supplemental_data_sets: expected[:supplemental_data_sets] || [],
          )
        end
      end
    end
  end

  # ApplicationController#valid_per_form_csrf_token? also accepts a token minted for the
  # encoded path IdProtector decodes. That token must stay bound to its action.
  describe 'per-form CSRF tokens with protected ids' do
    let(:bulk_entities_path) { bulk_entities_admin_collection_path(project_collection, entities: :data_sources) }
    let(:bulk_entities_params) { { collection: { data_sources: { data_source.id.to_s => '1' } } } }

    around do |example|
      forgery = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = forgery
    end

    before do
      stub_const('ProtectedId::PROTECT_IDS', true)
      # Starts the session the tokens are minted against.
      get entities_admin_collection_path(project_collection, entities: :data_sources)
    end

    def token_for(action)
      controller.send(:form_authenticity_token, form_options: { action: action, method: 'patch' })
    end

    it 'accepts a token minted for the encoded bulk entities path' do
      # This is verifying that the path is encoded and using ProtectedIDs
      expect(bulk_entities_path).to include('==')
      patch bulk_entities_path, params: bulk_entities_params.merge(authenticity_token: token_for(bulk_entities_path))
      expect(response).to have_http_status(:redirect)
      expect(project_collection.reload.data_sources).to contain_exactly(data_source)
    end

    it 'rejects a token minted for another action on the same collection' do
      patch bulk_entities_path, params: bulk_entities_params.merge(authenticity_token: token_for(admin_collection_path(project_collection)))
      expect(response).to have_http_status(:unprocessable_content)
      expect(project_collection.reload.data_sources).to be_empty
    end
  end
end
