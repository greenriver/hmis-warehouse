###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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

  let!(:project_coc) { create :hud_project_coc }
  let!(:project_coc_2) { create :hud_project_coc }
  let!(:data_source) { create :data_source_fixed_id }
  let!(:organization) { create :grda_warehouse_hud_organization }
  let!(:project_group) { create :project_group }
  let!(:project_group_2) { create :project_group }
  let!(:project) { create :grda_warehouse_hud_project, organization: organization }
  let!(:report) { create :core_demographics_report }
  let!(:cohort) { create :cohort }

  let!(:project_collection) { create :collection }
  let!(:legacy_project_collection) { create(:collection, :skip_validate, collection_type: nil) }

  before(:each) do
    sign_in admin
    admin.legacy_roles << admin_role
  end

  def run_entity_tests(collection:, coc_codes:, data_sources:, organizations:, projects:, project_groups:, project_access_groups:, reports:, cohorts:)
    collection.reload
    expect(collection.reload.coc_codes).to eq(coc_codes)
    expect(collection.reload.data_source_ids).to eq(data_sources)
    expect(collection.reload.organization_ids).to eq(organizations)
    expect(collection.reload.project_ids).to eq(projects)
    expect(collection.reload.project_group_ids).to eq(project_groups)
    expect(collection.reload.project_access_group_ids).to eq(project_access_groups)
    expect(collection.reload.report_ids).to eq(reports)
    expect(collection.reload.cohort_ids).to eq(cohorts)
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

  describe 'PUT update' do
    let(:viewable_params) do
      {
        collection: {
          coc_codes: ['XX-500', 'XX-501'],
          data_sources: [data_source.id],
          organizations: [organization.id],
          projects: [project.id],
          project_access_groups: [project_group.id],
          reports: [report.id],
          cohorts: [cohort.id],
          project_groups: [project_group_2.id],
        },
      }
    end

    it 'Updates collection name & description #update' do
      patch admin_collection_path(project_collection), params: {
        collection: {
          name: 'Updated Name',
          description: 'Updated Description',
        },
      }
      expect(project_collection.reload.name).to eq('Updated Name')
      expect(project_collection.reload.description).to eq('Updated Description')
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
      run_entity_tests(collection: legacy_project_collection,
                       coc_codes: viewable_params[:collection][:coc_codes],
                       data_sources: viewable_params[:collection][:data_sources],
                       organizations: viewable_params[:collection][:organizations],
                       projects: viewable_params[:collection][:projects],
                       project_groups: viewable_params[:collection][:project_groups],
                       project_access_groups: viewable_params[:collection][:project_access_groups],
                       reports: viewable_params[:collection][:reports],
                       cohorts: viewable_params[:collection][:cohorts])
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
      GrdaWarehouse::Hud::ProjectCoc.
        distinct.
        order(:CoCCode).
        pluck(:CoCCode).
        reject(&:blank?).
        compact.
        map { |coc| [coc, '0'] }.to_h
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
        },
      }
    end

    it 'Updating current collection viewables #bulk_entities' do
      coc_codes['XX-001'] = '1'
      data_sources[data_source.id.to_s] = '1'
      organizations[organization.id.to_s] = '1'
      projects[project.id.to_s] = '1'
      project_groups[project_group.id.to_s] = '1'
      project_access_groups[project_group.id.to_s] = '1'
      reports[report.id.to_s] = '1'
      cohorts[cohort.id.to_s] = '1'

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'coc_codes')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: ['XX-001'],
        data_sources: [],
        organizations: [],
        projects: [],
        project_groups: [],
        project_access_groups: [],
        reports: [],
        cohorts: [],
      )

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'data_sources')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: ['XX-001'],
        data_sources: [data_source.id],
        organizations: [],
        projects: [],
        project_groups: [],
        project_access_groups: [],
        reports: [],
        cohorts: [],
      )

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'organizations')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: ['XX-001'],
        data_sources: [data_source.id],
        organizations: [organization.id],
        projects: [],
        project_groups: [],
        project_access_groups: [],
        reports: [],
        cohorts: [],
      )

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'projects')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: ['XX-001'],
        data_sources: [data_source.id],
        organizations: [organization.id],
        projects: [project.id],
        project_groups: [],
        project_access_groups: [],
        reports: [],
        cohorts: [],
      )

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'project_groups')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: ['XX-001'],
        data_sources: [data_source.id],
        organizations: [organization.id],
        projects: [project.id],
        project_groups: [project_group.id],
        project_access_groups: [],
        reports: [],
        cohorts: [],
      )

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'project_access_groups')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: ['XX-001'],
        data_sources: [data_source.id],
        organizations: [organization.id],
        projects: [project.id],
        project_groups: [project_group.id],
        project_access_groups: [project_group.id],
        reports: [],
        cohorts: [],
      )

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'reports')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: ['XX-001'],
        data_sources: [data_source.id],
        organizations: [organization.id],
        projects: [project.id],
        project_groups: [project_group.id],
        project_access_groups: [project_group.id],
        reports: [report.id],
        cohorts: [],
      )

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'cohorts')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: ['XX-001'],
        data_sources: [data_source.id],
        organizations: [organization.id],
        projects: [project.id],
        project_groups: [project_group.id],
        project_access_groups: [project_group.id],
        reports: [report.id],
        cohorts: [cohort.id],
      )

      coc_codes['XX-001'] = '0'
      data_sources[data_source.id.to_s] = '0'
      organizations[organization.id.to_s] = '0'
      projects[project.id.to_s] = '0'
      project_groups[project_group.id.to_s] = '0'
      project_access_groups[project_group.id.to_s] = '0'
      reports[report.id.to_s] = '0'
      cohorts[cohort.id.to_s] = '0'

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'coc_codes')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: [],
        data_sources: [data_source.id],
        organizations: [organization.id],
        projects: [project.id],
        project_groups: [project_group.id],
        project_access_groups: [project_group.id],
        reports: [report.id],
        cohorts: [cohort.id],
      )

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'data_sources')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: [],
        data_sources: [],
        organizations: [organization.id],
        projects: [project.id],
        project_groups: [project_group.id],
        project_access_groups: [project_group.id],
        reports: [report.id],
        cohorts: [cohort.id],
      )

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'organizations')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: [],
        data_sources: [],
        organizations: [],
        projects: [project.id],
        project_groups: [project_group.id],
        project_access_groups: [project_group.id],
        reports: [report.id],
        cohorts: [cohort.id],
      )

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'projects')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: [],
        data_sources: [],
        organizations: [],
        projects: [],
        project_groups: [project_group.id],
        project_access_groups: [project_group.id],
        reports: [report.id],
        cohorts: [cohort.id],
      )

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'project_groups')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: [],
        data_sources: [],
        organizations: [],
        projects: [],
        project_groups: [],
        project_access_groups: [project_group.id],
        reports: [report.id],
        cohorts: [cohort.id],
      )

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'project_access_groups')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: [],
        data_sources: [],
        organizations: [],
        projects: [],
        project_groups: [],
        project_access_groups: [],
        reports: [report.id],
        cohorts: [cohort.id],
      )

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'reports')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: [],
        data_sources: [],
        organizations: [],
        projects: [],
        project_groups: [],
        project_access_groups: [],
        reports: [],
        cohorts: [cohort.id],
      )

      patch bulk_entities_admin_collection_path(legacy_project_collection), params: bulk_entities_params.merge(entities: 'cohorts')
      run_entity_tests(
        collection: legacy_project_collection,
        coc_codes: [],
        data_sources: [],
        organizations: [],
        projects: [],
        project_groups: [],
        project_access_groups: [],
        reports: [],
        cohorts: [],
      )
    end
  end
end
