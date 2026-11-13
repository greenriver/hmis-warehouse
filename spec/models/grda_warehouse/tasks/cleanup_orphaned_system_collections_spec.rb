###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::CleanupOrphanedSystemCollections do
  describe '#run! (candidate detection)' do
    it 'returns no candidates when there are none' do
      result = described_class.new(dry_run: true).run!

      expect(result[:candidates]).to eq([])
    end

    it 'flags a collection whose entity was hard-deleted' do
      cohort = create(:cohort)
      collection = cohort.viewable_access_control.collection
      cohort.really_destroy!

      result = described_class.new(dry_run: true).run!

      expect(result[:candidates].map { |c| c[:id] }).to contain_exactly(collection.id)
    end

    it 'flags a collection whose entity was soft-deleted' do
      cohort = create(:cohort)
      collection = cohort.viewable_access_control.collection
      cohort.destroy

      result = described_class.new(dry_run: true).run!

      expect(result[:candidates].map { |c| c[:id] }).to contain_exactly(collection.id)
    end

    it 'flags a legacy system collection created with zero entities' do
      legacy_collection = Collection.create!(name: 'Legacy Orphan', collection_type: 'Projects', system: ['Entities'])

      result = described_class.new(dry_run: true).run!

      expect(result[:candidates].map { |c| c[:id] }).to contain_exactly(legacy_collection.id)
    end

    it 'does not flag a collection whose entity is still live' do
      cohort = create(:cohort)
      cohort.viewable_access_control

      result = described_class.new(dry_run: true).run!

      expect(result[:candidates]).to eq([])
    end

    it 'does not flag a non-system collection with zero entities' do
      create(:collection)

      result = described_class.new(dry_run: true).run!

      expect(result[:candidates]).to eq([])
    end

    it 'does not flag a must_exist aggregate collection regardless of entity count' do
      Collection.system_collections

      result = described_class.new(dry_run: true).run!

      expect(result[:candidates]).to eq([])
    end

    it 'excludes (rather than flags) a collection referencing an unrecognized entity_type' do
      cohort = create(:cohort)
      collection = cohort.viewable_access_control.collection
      record = GrdaWarehouse::GroupViewableEntity.new(
        collection_id: collection.id,
        entity_type: 'NoSuchClass',
        entity_id: 999_999,
        access_group_id: 0,
      )
      record.save(validate: false)

      result = described_class.new(dry_run: true).run!

      expect(result[:candidates].map { |c| c[:id] }).not_to include(collection.id)
    end
  end

  describe '#run! (dry run vs. live deletion)' do
    let(:cohort) { create(:cohort) }
    let(:access_control) { cohort.viewable_access_control }
    let(:collection) { access_control.collection }

    before do
      collection
      cohort.really_destroy!
    end

    it 'does not delete anything in dry run mode' do
      described_class.new(dry_run: true).run!

      expect(Collection.find_by(id: collection.id)).to be_present
    end

    it 'does not record a maintenance task run in dry run mode' do
      expect { described_class.new(dry_run: true).run! }.
        not_to change(GrdaWarehouse::Tasks::SystemMaintenanceTaskRun, :count)
    end

    it 'records a completed maintenance task run in live mode' do
      expect { described_class.new(dry_run: false).run! }.
        to change(GrdaWarehouse::Tasks::SystemMaintenanceTaskRun, :count).by(1)
      expect(GrdaWarehouse::Tasks::SystemMaintenanceTaskRun.last.completed_at).to be_present
    end

    it 'reports failures to Sentry with the failure count' do
      allow_any_instance_of(Collection).to receive(:destroy_with_associated_records!).and_raise(StandardError, 'simulated failure')

      expect(Sentry).to receive(:capture_exception_with_info) do |error, *|
        expect(error).to be_a(StandardError)
        expect(error.message).to include('1 collection(s) failed to destroy')
      end

      described_class.new(dry_run: false).run!
    end

    it 'does not report to Sentry when nothing fails' do
      expect(Sentry).not_to receive(:capture_exception_with_info)

      described_class.new(dry_run: false).run!
    end

    it 'deletes the candidate in live mode via the safe, reversible teardown' do
      result = described_class.new(dry_run: false).run!

      expect(Collection.find_by(id: collection.id)).to be_nil
      expect(result[:destroyed_ids]).to contain_exactly(collection.id)
      # Both assertions below only pass if this went through destroy_with_associated_records!,
      # not a bare destroy! (would skip the AccessControl cleanup) or really_destroy! (irreversible).
      expect(Collection.with_deleted.find(collection.id)).to be_present
      expect(AccessControl.find_by(id: access_control.id)).to be_nil
    end

    it 'continues processing remaining candidates when one fails to delete' do
      other_cohort = create(:cohort)
      other_collection = other_cohort.viewable_access_control.collection
      other_cohort.really_destroy!

      allow_any_instance_of(Collection).to receive(:destroy_with_associated_records!) do |instance|
        raise StandardError, 'simulated failure' if instance.id == collection.id

        instance.destroy!
      end

      result = described_class.new(dry_run: false).run!

      expect(result[:failed]).to contain_exactly({ id: collection.id, error: 'simulated failure' })
      expect(result[:destroyed_ids]).to contain_exactly(other_collection.id)
      expect(Collection.find_by(id: collection.id)).to be_present # destroy failed, still there
      expect(Collection.find_by(id: other_collection.id)).to be_nil # destroyed fine
    end
  end
end
