###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GrdaWarehouseBase PaperTrail configuration', type: :model do
  # GrdaWarehouseBase forces every warehouse model to record versions into
  # GrdaWarehouse::Version. Unlike HealthBase it does not enable paper_trail in
  # its own body, so each concrete model declares it once (the super path). A
  # second declaration (e.g. an abstract base plus a subclass) is merged in
  # place -- like HealthBase -- rather than raising.
  #
  # The `test_paper_trail_models` table carries a lock_version column so the
  # implicit `skip: [:lock_version]` default (grda_warehouse_base.rb) can be
  # exercised behaviorally via optimistic locking.
  before(:all) do
    GrdaWarehouseBase.connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS test_paper_trail_models (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255),
        description TEXT,
        lock_version INTEGER DEFAULT 0,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
      )
    SQL

    class TestPaperTrailModel < GrdaWarehouseBase
      self.table_name = 'test_paper_trail_models'
      has_paper_trail
    end

    class TestPaperTrailParent < GrdaWarehouseBase
      self.table_name = 'test_paper_trail_models'
      has_paper_trail
    end

    class TestPaperTrailChild < TestPaperTrailParent
      has_paper_trail ignore: [:description, :updated_at]
    end

    # Regression fixture for the reported bug: two has_paper_trail declarations
    # on a single class. The first call hits the super path; the second must
    # merge in place rather than re-run setup (which historically wrote a
    # duplicate version into the primary database's default versions table).
    class TestDoubleDeclareModel < GrdaWarehouseBase
      self.table_name = 'test_paper_trail_models'
      has_paper_trail
      has_paper_trail
    end

    # Merge-semantics fixtures: a parent that already configures an option and a
    # child that re-declares the same option. The contract is per-key overwrite:
    # the child inherits keys it does not set and replaces any key it does set
    # (ignore/skip/only replace wholesale; meta merges at the sub-key level with
    # the child winning on conflict).
    class TestMergeParent < GrdaWarehouseBase
      self.table_name = 'test_paper_trail_models'
      has_paper_trail ignore: [:description, :updated_at]
    end

    class TestMergeChild < TestMergeParent
      has_paper_trail ignore: [:name, :updated_at]
    end

    # Separate fixtures for meta: paper_trail persists each meta key as a column
    # on the version record, so these are only ever inspected / resolved via
    # paper_trail_meta_value -- never create!'d (parent_key/child_key are not real
    # version columns).
    class TestMetaParent < GrdaWarehouseBase
      self.table_name = 'test_paper_trail_models'
      has_paper_trail meta: { parent_key: :name, shared: :name }
    end

    class TestMetaChild < TestMetaParent
      has_paper_trail meta: { child_key: :description, shared: :description }
    end

    class TestOnlyParent < GrdaWarehouseBase
      self.table_name = 'test_paper_trail_models'
      has_paper_trail only: [:name]
    end

    class TestOnlyChild < TestOnlyParent
      has_paper_trail only: [:description]
    end

    class TestSkipParent < GrdaWarehouseBase
      self.table_name = 'test_paper_trail_models'
      has_paper_trail skip: [:description]
    end

    class TestSkipChild < TestSkipParent
      has_paper_trail skip: [:name]
    end
  end

  after(:all) do
    GrdaWarehouseBase.connection.execute('DROP TABLE IF EXISTS test_paper_trail_models CASCADE')
    [
      :TestPaperTrailChild, :TestPaperTrailParent, :TestPaperTrailModel,
      :TestDoubleDeclareModel,
      :TestMergeChild, :TestMergeParent,
      :TestMetaChild, :TestMetaParent,
      :TestOnlyChild, :TestOnlyParent,
      :TestSkipChild, :TestSkipParent
    ].each do |const|
      Object.send(:remove_const, const) if Object.const_defined?(const)
    end
  end

  around(:example) do |ex|
    PaperTrailHelper.with_paper_trail do
      PaperTrail.request.enabled = true
      ex.run
    ensure
      PaperTrail.request.enabled = false
    end
  end

  describe 'a model that declares has_paper_trail once (super path)' do
    it 'records exactly one version on create, and nothing in the default (primary) versions table' do
      expect do
        TestPaperTrailModel.create!(name: 'Test', description: 'Test Description')
      end.to change(GrdaWarehouse::Version, :count).by(1).and change(PaperTrail::Version, :count).by(0)
    end

    it 'records exactly one version on update' do
      record = TestPaperTrailModel.create!(name: 'Test', description: 'Original')

      expect do
        record.update!(description: 'Updated')
      end.to change(GrdaWarehouse::Version, :count).by(1)
    end

    it 'records exactly one version on destroy' do
      record = TestPaperTrailModel.create!(name: 'Test', description: 'To Delete')

      expect do
        record.destroy
      end.to change(GrdaWarehouse::Version, :count).by(1)
    end

    it 'records exactly one version when a class declares has_paper_trail twice in its own body' do
      # The reported bug: a duplicate has_paper_trail declaration on a single
      # class produced two version records (the extra one landing in the primary
      # database's default versions table). The second call must merge in place,
      # not re-run setup -- so a create still writes exactly one version, and
      # nothing lands in PaperTrail::Version.
      expect do
        TestDoubleDeclareModel.create!(name: 'Test', description: 'x')
      end.to change(GrdaWarehouse::Version, :count).by(1).and change(PaperTrail::Version, :count).by(0)
    end

    it 'stores versions via GrdaWarehouse::Version' do
      record = TestPaperTrailModel.create!(name: 'Test', description: 'Check Version')
      version = GrdaWarehouse::Version.where(item_type: 'TestPaperTrailModel', item_id: record.id).last

      expect(version).to be_present
      expect(version.event).to eq('create')
      expect(TestPaperTrailModel.version_class_name).to eq('GrdaWarehouse::Version')
      # The original bug wrote the duplicate version into the primary database's
      # default versions table; confirm nothing landed there.
      expect(PaperTrail::Version.where(item_type: 'TestPaperTrailModel', item_id: record.id)).to be_empty
    end

    it 'applies the default lock_version skip -- the changed lock_version is not recorded' do
      # Optimistic locking bumps lock_version on every update. Because the
      # default skip includes lock_version, it must be absent from the recorded
      # changeset even though its value changed.
      record = TestPaperTrailModel.create!(name: 'Test', description: 'Original')
      original_lock = record.lock_version

      record.update!(description: 'Updated')
      changed_keys = record.versions.reload.last.changeset.keys.map(&:to_s)

      expect(record.reload.lock_version).to be > original_lock # lock_version really changed
      expect(changed_keys).to include('description')
      expect(changed_keys).not_to include('lock_version')
    end
  end

  describe 'a subclass that re-declares has_paper_trail (merge path)' do
    it 'does not raise and keeps GrdaWarehouse::Version' do
      # before(:all) already re-declared has_paper_trail without raising
      expect(TestPaperTrailChild.version_class_name).to eq('GrdaWarehouse::Version')
    end

    it 'records exactly one version on create, and nothing in the default (primary) versions table' do
      expect do
        TestPaperTrailChild.create!(name: 'Test', description: 'x')
      end.to change(GrdaWarehouse::Version, :count).by(1).and change(PaperTrail::Version, :count).by(0)
    end

    it 'honors the ignore option merged from the subclass' do
      record = TestPaperTrailChild.create!(name: 'Test', description: 'x')

      expect do
        record.update!(description: 'y')
      end.not_to change(GrdaWarehouse::Version, :count)

      expect do
        record.update!(name: 'Renamed')
      end.to change(GrdaWarehouse::Version, :count).by(1)
    end

    it 'preserves the inherited lock_version skip through the merge' do
      # The subclass never re-declared skip, so the merge must keep the parent's
      # lock_version skip: an update records the changed attribute but not the
      # bumped lock_version.
      record = TestPaperTrailChild.create!(name: 'Test', description: 'x')
      original_lock = record.lock_version

      record.update!(name: 'Renamed')
      changed_keys = record.versions.reload.last.changeset.keys.map(&:to_s)

      expect(record.reload.lock_version).to be > original_lock
      expect(changed_keys).to include('name')
      expect(changed_keys).not_to include('lock_version')
    end
  end

  describe 'merge overwrite semantics (child config replaces parent per key)' do
    describe 'ignore' do
      it 'replaces the parent ignore list rather than unioning it' do
        # Parent ignored :description; child re-declares ignore: [:name, :updated_at].
        # After the merge the child ignores name (not description), so an update
        # that changes both records description but not name.
        record = TestMergeChild.create!(name: 'A', description: 'original')

        record.update!(name: 'B', description: 'changed')
        changed_keys = record.versions.reload.last.changeset.keys.map(&:to_s)

        # parent's :description ignore was dropped -> description is now tracked
        expect(changed_keys).to include('description')
        # child's own ignore still applies
        expect(changed_keys).not_to include('name')
      end
    end

    describe 'meta' do
      it 'merges parent and child meta, with the child winning on a shared key' do
        merged = TestMetaChild.paper_trail_options[:meta]

        expect(merged.keys).to include(:parent_key, :child_key, :shared)
        expect(merged[:shared]).to eq(:description) # child's value, not the parent's :name
      end

      it 'resolves merged meta values against the instance' do
        record = TestMetaChild.new(name: 'A', description: 'B')

        expect(record.paper_trail_meta_value(:parent_key)).to eq('A') # inherited from parent
        expect(record.paper_trail_meta_value(:child_key)).to eq('B')  # added by child
        expect(record.paper_trail_meta_value(:shared)).to eq('B')     # child overrode parent
      end
    end

    describe 'only' do
      it 'replaces the parent only list rather than unioning it' do
        # Parent tracked only :name; child re-declares only: [:description].
        record = TestOnlyChild.create!(name: 'A', description: 'original')

        # name is no longer in the only-list -> changing it alone records nothing
        expect do
          record.update!(name: 'B')
        end.not_to change(GrdaWarehouse::Version, :count)

        # description is the child's only-list -> changing it records a version
        expect do
          record.update!(description: 'changed')
        end.to change(GrdaWarehouse::Version, :count).by(1)
      end
    end

    describe 'skip' do
      it 'replaces the parent skip list rather than unioning it' do
        # Parent skipped :description; child re-declares skip: [:name]. After the
        # merge the child skips name (not description), so an update that changes
        # both records description but not name. Asserting on the recorded
        # changeset (rather than paper_trail_options directly) also proves the
        # merge stringifies skip: symbol entries would silently stop filtering at
        # event time because PaperTrail subtracts skip from the string-keyed list
        # of changed attributes.
        record = TestSkipChild.create!(name: 'A', description: 'original')

        record.update!(name: 'B', description: 'changed')
        changed_keys = record.versions.reload.last.changeset.keys.map(&:to_s)

        # child's own skip still applies
        expect(changed_keys).not_to include('name')
        # parent's :description skip was dropped -> description is now tracked
        expect(changed_keys).to include('description')
      end
    end
  end
end
