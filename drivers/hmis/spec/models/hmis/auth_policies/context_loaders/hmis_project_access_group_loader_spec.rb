# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::ContextLoaders::HmisProjectAccessGroupLoader, type: :model do
  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hmis_hud_organization, data_source: data_source) }
  let!(:project) { create(:hmis_hud_project, data_source: data_source, organization: organization) }
  let!(:access_group) { create(:hmis_access_group) }
  let(:loader) { described_class.new }

  describe '#get' do
    context 'when access is granted via project' do
      before do
        create(
          :hmis_group_viewable_entity,
          collection: access_group,
          entity: project,
        )
      end

      it 'returns the access group ID' do
        result = loader.get(project.id)
        expect(result).to eq([access_group.id])
      end
    end

    context 'when no access is granted' do
      it 'returns empty array' do
        result = loader.get(project.id)
        expect(result).to eq([])
      end
    end

    context 'when access group is deleted' do
      before do
        create(
          :hmis_group_viewable_entity,
          collection: access_group,
          entity: project,
        )
        access_group.update!(deleted_at: Time.current)
      end

      it 'should not return deleted access group ID' do
        result = loader.get(project.id)
        expect(result).to eq([])
      end
    end

    context 'when data source is deleted' do
      before do
        create(
          :hmis_group_viewable_entity,
          collection: access_group,
          entity: data_source,
        )
        data_source.update!(deleted_at: Time.current)
      end

      it 'does not return access group ID' do
        result = loader.get(project.id)
        expect(result).to eq([])
      end
    end

    context 'when organization is deleted' do
      before do
        create(
          :hmis_group_viewable_entity,
          collection: access_group,
          entity: organization,
        )
        organization.update!(DateDeleted: Time.current)
      end

      it 'does not return access group ID' do
        result = loader.get(project.id)
        expect(result).to eq([])
      end
    end

    context 'when project group is deleted' do
      let!(:project_group) { create(:hmis_project_group) }

      before do
        project.project_groups << project_group
        create(
          :hmis_group_viewable_entity,
          collection: access_group,
          entity: project_group,
        )
        project_group.update!(deleted_at: Time.current)
      end

      it 'does not return access group ID' do
        result = loader.get(project.id)
        expect(result).to eq([])
      end
    end
  end

  describe '#preload' do
    let!(:project_2) { create(:hmis_hud_project, data_source: data_source, organization: organization) }
    let!(:access_group_2) { create(:hmis_access_group) }

    before do
      create(
        :hmis_group_viewable_entity,
        collection: access_group,
        entity: project,
      )
      create(
        :hmis_group_viewable_entity,
        collection: access_group_2,
        entity: project_2,
      )
    end

    it 'preloads multiple projects efficiently' do
      loader.preload([project.id, project_2.id])

      expect(loader.get(project.id)).to eq([access_group.id])
      expect(loader.get(project_2.id)).to eq([access_group_2.id])
    end

    it 'handles empty project_ids array' do
      expect { loader.preload([]) }.not_to raise_error
    end

    it 'handles duplicate project_ids' do
      loader.preload([project.id, project.id])
      expect(loader.get(project.id)).to eq([access_group.id])
    end

    context 'with deleted access group' do
      before do
        access_group_2.update!(deleted_at: Time.current)
      end

      it 'excludes deleted access groups from preload results' do
        loader.preload([project.id, project_2.id])

        expect(loader.get(project.id)).to eq([access_group.id])
        expect(loader.get(project_2.id)).to eq([])
      end
    end
  end
end
