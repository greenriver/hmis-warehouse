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

  def run_entity_tests(collection:, coc_codes: [], data_sources: [], organizations: [], projects: [], project_groups: [], project_access_groups: [], reports: [], cohorts: [])
    collection.reload
    expect(collection.coc_codes).to eq(coc_codes)
    expect(collection.data_source_ids).to eq(data_sources)
    expect(collection.organization_ids).to eq(organizations)
    expect(collection.project_ids).to eq(projects)
    expect(collection.project_group_ids).to eq(project_groups)
    expect(collection.project_access_group_ids).to eq(project_access_groups)
    expect(collection.report_ids).to eq(reports)
    expect(collection.cohort_ids).to eq(cohorts)
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
          coc_codes: [project_coc.coc_code],
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
      # Set some base vieawables. We want to make sure these dont change.
      project_collection.coc_codes = [project_coc.coc_code]
      project_collection.set_viewables({
                                         data_sources: [data_source.id],
                                         organizations: [organization.id],
                                         projects: [project.id],
                                         project_groups: [project_group_2.id],
                                         project_access_groups: [project_group.id],
                                         reports: [report.id],
                                         cohorts: [cohort.id],
                                       })
      project_collection.save!
      # make sure the viewables exist
      run_entity_tests(collection: project_collection,
                       coc_codes: [project_coc.coc_code],
                       data_sources: [data_source.id],
                       organizations: [organization.id],
                       projects: [project.id],
                       project_groups: [project_group_2.id],
                       project_access_groups: [project_group.id],
                       reports: [report.id],
                       cohorts: [cohort.id])

      patch admin_collection_path(project_collection), params: {
        collection: {
          name: 'Updated Name',
          description: 'Updated Description',
        },
      }
      expect(project_collection.reload.name).to eq('Updated Name')
      expect(project_collection.reload.description).to eq('Updated Description')

      # make sure the viewables are not changed
      run_entity_tests(collection: project_collection,
                       coc_codes: [project_coc.coc_code],
                       data_sources: [data_source.id],
                       organizations: [organization.id],
                       projects: [project.id],
                       project_groups: [project_group_2.id],
                       project_access_groups: [project_group.id],
                       reports: [report.id],
                       cohorts: [cohort.id])
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
      expected = {}

      coc_codes[project_coc.coc_code] = '1'
      data_sources[data_source.id.to_s] = '1'
      organizations[organization.id.to_s] = '1'
      projects[project.id.to_s] = '1'
      project_groups[project_group.id.to_s] = '1'
      project_access_groups[project_group.id.to_s] = '1'
      reports[report.id.to_s] = '1'
      cohorts[cohort.id.to_s] = '1'

      # Each entity should only be updating their corresponding viewable on the collection and should not be changing the values of the other entities
      ['coc_codes', 'data_sources', 'organizations', 'projects', 'project_groups', 'project_access_groups', 'reports', 'cohorts'].each do |entity|
        # Set the expected value for this specific entity. Any entity that had previously been set will remain, but all future entities in the loop will still be expected to have a [] value.
        # This will help ensure that only the expected entity is being updated.
        expected[entity.to_sym] = bulk_entities_params[:collection][entity.to_sym].keys.select { |k| bulk_entities_params[:collection][entity.to_sym][k] == '1' }
        expected[entity.to_sym] = expected[entity.to_sym].map(&:to_i) unless entity == 'coc_codes'
        # Update the entity on the collection
        patch bulk_entities_admin_collection_path(project_collection), params: bulk_entities_params.merge(entities: entity)
        # Verify the updated collection
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
        )
      end

      # We are now going to remove each entity and ensure that only the entity being removed is affected
      coc_codes[project_coc.coc_code] = '0'
      data_sources[data_source.id.to_s] = '0'
      organizations[organization.id.to_s] = '0'
      projects[project.id.to_s] = '0'
      project_groups[project_group.id.to_s] = '0'
      project_access_groups[project_group.id.to_s] = '0'
      reports[report.id.to_s] = '0'
      cohorts[cohort.id.to_s] = '0'

      ['coc_codes', 'data_sources', 'organizations', 'projects', 'project_groups', 'project_access_groups', 'reports', 'cohorts'].each do |entity|
        # Set the expected value for this specific entity to []. Any entity that had previously been set will also be an empty array, but all future entities in the
        # loop will still be expected to have a previously set value. This will help ensure that only the expected entity is being updated.
        expected[entity.to_sym] = []
        # Update the entity on the collection
        patch bulk_entities_admin_collection_path(project_collection), params: bulk_entities_params.merge(entities: entity)
        # Verify the updated collection
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
        )
      end
    end
  end
end
