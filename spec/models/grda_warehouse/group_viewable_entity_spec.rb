###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::GroupViewableEntity do
  describe '.describe_changes' do
    let(:access_group) { create(:access_group) }
    let(:collection) { create(:collection) }

    # describe_changes reads the version through the best-effort accessors, which return nil when the
    # underlying YAML can't be deserialized. Model a deserialization failure by passing nil.
    def version_double(event:, object: nil, object_changes: nil)
      double('Version', id: 1, event: event, item: nil, safe_object: object, safe_object_changes: object_changes)
    end

    it 'resolves the access group from the object column when collection_id is a nil-valued key' do
      # GroupViewableEntity always has both columns in its serialized object; only one is ever
      # populated. The path resolution must key off presence of a value, not presence of the key.
      version = version_double(
        event: 'create',
        object: { 'entity_id' => nil, 'entity_type' => nil, 'collection_id' => nil, 'access_group_id' => access_group.id },
      )

      description = described_class.describe_changes(version, nil, [])

      expect(description.join).to include(access_group.name)
      expect(description.join).not_to include('Collection ID')
    end

    it 'resolves the collection from the object column when access_group_id is a nil-valued key' do
      version = version_double(
        event: 'create',
        object: { 'entity_id' => nil, 'entity_type' => nil, 'collection_id' => collection.id, 'access_group_id' => nil },
      )

      description = described_class.describe_changes(version, nil, [])

      expect(description.join).to include(collection.name)
      expect(description.join).not_to include('Access Group ID')
    end

    it 'recovers via the object column when object_changes fails to deserialize (safe_object_changes nil)' do
      version = version_double(
        event: 'create',
        object: { 'entity_id' => nil, 'entity_type' => nil, 'access_group_id' => access_group.id },
        object_changes: nil,
      )

      result = nil
      expect { result = described_class.describe_changes(version, nil, []) }.not_to raise_error
      expect(result.join).to include(access_group.name)
    end

    it 'falls back to Unknown Entity/Collection when both object and object_changes fail to deserialize' do
      version = version_double(event: 'update', object: nil, object_changes: nil)

      description = described_class.describe_changes(version, nil, [])

      expect(description.join).to include('Unknown Entity')
      expect(description.join).to include('Unknown Collection or Group')
    end

    it 'degrades to the entity id (does not raise) when entity_type references a removed class' do
      version = version_double(
        event: 'create',
        object: { 'entity_id' => 42, 'entity_type' => 'GrdaWarehouse::NoSuchRemovedEntityClass', 'access_group_id' => access_group.id },
      )

      result = nil
      expect { result = described_class.describe_changes(version, nil, []) }.not_to raise_error
      expect(result.join).to include('Entity ID 42')
      expect(result.join).to include(access_group.name)
    end
  end
end
