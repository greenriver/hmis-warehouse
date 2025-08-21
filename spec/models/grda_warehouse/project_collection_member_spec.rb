# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe GrdaWarehouse::ProjectCollectionMember, type: :model do
  let!(:data_source) { create(:data_source_fixed_id) }
  let!(:organization) { create(:hud_organization, data_source: data_source) }
  let!(:project) { create(:grda_warehouse_hud_project, data_source: data_source, organization: organization) }
  let!(:collection) { create(:collection) }

  subject { described_class.where(project_id: project.id, collection_id: collection.id) }

  context 'when access is granted via data source' do
    before do
      create(
        :grda_warehouse_group_viewable_entity,
        collection: collection,
        entity: data_source,
      )
    end
    it { is_expected.to exist }
  end

  context 'when access is granted via project' do
    before do
      create(
        :grda_warehouse_group_viewable_entity,
        collection: collection,
        entity: project,
      )
    end
    it { is_expected.to exist }
  end

  context 'when access is granted via organization' do
    before do
      create(
        :grda_warehouse_group_viewable_entity,
        collection: collection,
        entity: organization,
      )
    end
    it { is_expected.to exist }
  end

  context 'when access is granted via project group' do
    let!(:project_group) { create(:project_access_group) }
    before do
      project.project_groups << project_group
      create(
        :grda_warehouse_group_viewable_entity,
        collection: collection,
        entity: project_group,
      )
    end
    it { is_expected.to exist }
  end

  context 'when no access is granted' do
    it { is_expected.not_to exist }
  end

  context 'when related records are soft-deleted' do
    context 'when the project is deleted' do
      before do
        create(
          :grda_warehouse_group_viewable_entity,
          collection: collection,
          entity: project,
        )
        project.update!(DateDeleted: Time.current)
      end
      it { is_expected.not_to exist }
    end

    context 'when the organization is deleted' do
      before do
        create(
          :grda_warehouse_group_viewable_entity,
          collection: collection,
          entity: organization,
        )
        organization.update!(DateDeleted: Time.current)
      end
      it { is_expected.not_to exist }
    end

    context 'when the project group is deleted' do
      let!(:project_group) { create(:project_access_group) }

      before do
        project.project_groups << project_group
        create(
          :grda_warehouse_group_viewable_entity,
          collection: collection,
          entity: project_group,
        )
        project_group.update!(deleted_at: Time.current)
      end
      it { is_expected.not_to exist }
    end

    context 'when the group viewable entity is deleted' do
      before do
        gve = create(
          :grda_warehouse_group_viewable_entity,
          collection: collection,
          entity: project,
        )
        gve.update!(deleted_at: Time.current)
      end
      it { is_expected.not_to exist }
    end
  end

  context 'when access is granted by multiple entities' do
    context 'when the organization is deleted but project access remains' do
      before do
        create(
          :grda_warehouse_group_viewable_entity,
          collection: collection,
          entity: organization,
        )
        create(
          :grda_warehouse_group_viewable_entity,
          collection: collection,
          entity: project,
        )
        organization.update!(DateDeleted: Time.current)
      end
      it { is_expected.to exist }
    end

    context 'when access is granted via organization and project group' do
      let!(:project_group) { create(:project_access_group) }

      before do
        project.project_groups << project_group
        create(
          :grda_warehouse_group_viewable_entity,
          collection: collection,
          entity: organization,
        )
        create(
          :grda_warehouse_group_viewable_entity,
          collection: collection,
          entity: project_group,
        )
      end

      it 'returns a single record' do
        expect(subject.count).to eq(1)
      end
    end

    context 'when project belongs to multiple project groups' do
      let!(:project_group_1) { create(:project_access_group) }
      let!(:project_group_2) { create(:project_access_group) }

      before do
        project.project_groups << project_group_1
        project.project_groups << project_group_2
        create(
          :grda_warehouse_group_viewable_entity,
          collection: collection,
          entity: project_group_1,
        )
        create(
          :grda_warehouse_group_viewable_entity,
          collection: collection,
          entity: project_group_2,
        )
      end

      it 'returns a single record' do
        expect(subject.count).to eq(1)
      end
    end
  end
end
