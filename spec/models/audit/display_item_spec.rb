###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Audit::DisplayItem do
  describe '#changes' do
    let(:access_group) { create(:access_group) }

    # An unsaved version whose item no longer resolves (so `version.item` is nil), with the
    # changeset computation stubbed to fail the way a corrupted/disallowed-class YAML payload would.
    def broken_changeset_version
      version = GrdaWarehouse::Version.new(item_type: 'GrdaWarehouse::GroupViewableEntity', item_id: 0, event: 'create')
      allow(version).to receive(:changes_with_computed_fallback).and_raise(StandardError, 'boom')
      allow(version).to receive(:anonymous?).and_return(true)
      allow(version).to receive(:clean_true_user_id).and_return(nil)
      allow(version).to receive(:clean_user_id).and_return(nil)
      allow(version).to receive(:whodunnit).and_return(nil)
      allow(version).to receive(:object).and_return('entity_id' => nil, 'entity_type' => nil, 'access_group_id' => access_group.id)
      allow(version).to receive(:object_changes).and_return(nil)
      version
    end

    it 'falls back to describe_changes without a changeset when the changeset fails to compute' do
      item = described_class.new(broken_changeset_version, {})

      expect(item.error).to be true
      expect(item.changes.join).to include(access_group.name)
    end

    it 'falls back to a generic error message when describe_changes without a changeset also fails' do
      version = broken_changeset_version
      allow(version).to receive(:object).and_raise(StandardError, 'boom')
      allow(version).to receive(:object_changes).and_raise(StandardError, 'boom')

      item = described_class.new(version, {})

      expect(item.error).to be true
      expect(item.changes).to eq(['Error loading changes'])
    end
  end
end
