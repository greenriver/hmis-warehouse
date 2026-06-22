###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Audit::CohortAccess::Intervals do
  # Fixed, ordered timestamps for deterministic interval math
  let(:t0) { Time.zone.parse('2025-01-01 00:00:00') }
  let(:t1) { Time.zone.parse('2025-02-01 00:00:00') }
  let(:t2) { Time.zone.parse('2025-03-01 00:00:00') }
  let(:t3) { Time.zone.parse('2025-04-01 00:00:00') }

  def interval(start_at, end_at)
    Audit::CohortAccess::Interval.new(start_at, end_at)
  end

  describe '.merge' do
    it 'returns an empty array for no intervals' do
      expect(described_class.merge([])).to eq([])
    end

    it 'merges overlapping intervals into one' do
      result = described_class.merge([interval(t0, t2), interval(t1, t3)])
      expect(result).to eq([interval(t0, t3)])
    end

    it 'keeps disjoint intervals separate and sorted' do
      result = described_class.merge([interval(t2, t3), interval(t0, t1)])
      expect(result).to eq([interval(t0, t1), interval(t2, t3)])
    end

    it 'treats a nil end as open-ended and absorbs later intervals' do
      result = described_class.merge([interval(t0, nil), interval(t1, t2)])
      expect(result).to eq([interval(t0, nil)])
    end
  end

  describe '.intersect' do
    it 'returns the overlap of two interval lists' do
      result = described_class.intersect([interval(t0, t2)], [interval(t1, t3)])
      expect(result).to eq([interval(t1, t2)])
    end

    it 'returns empty when there is no overlap' do
      result = described_class.intersect([interval(t0, t1)], [interval(t2, t3)])
      expect(result).to eq([])
    end

    it 'intersects open-ended intervals' do
      result = described_class.intersect([interval(t0, nil)], [interval(t1, nil)])
      expect(result).to eq([interval(t1, nil)])
    end

    it 'intersects three lists' do
      result = described_class.intersect([interval(t0, t3)], [interval(t1, t3)], [interval(t2, t3)])
      expect(result).to eq([interval(t2, t3)])
    end
  end

  describe '.reconstruct' do
    # Lightweight stand-in for a PaperTrail version's data, so the state machine can be tested without
    # depending on PaperTrail's object_changes serialization (which only round-trips on real versions).
    FakeVersion = Struct.new(:event, :created_at, :changeset, :id, keyword_init: true) do
      def changes_with_computed_fallback
        changeset
      end
    end

    def version(event:, created_at:, deleted_at_change: nil, id: 1)
      changeset = { 'id' => [nil, 1] }
      changeset['deleted_at'] = deleted_at_change if deleted_at_change
      FakeVersion.new(event: event, created_at: created_at, changeset: changeset, id: id)
    end

    it 'returns a single open interval for a create with no later changes' do
      versions = [version(event: 'create', created_at: t0)]
      expect(described_class.reconstruct(versions, record: nil)).to eq([interval(t0, nil)])
    end

    it 'closes the interval on a destroy event (paranoia soft-delete)' do
      versions = [
        version(event: 'create', created_at: t0, id: 1),
        version(event: 'destroy', created_at: t1, id: 2),
      ]
      expect(described_class.reconstruct(versions, record: nil)).to eq([interval(t0, t1)])
    end

    it 'closes the interval when an update sets deleted_at' do
      versions = [
        version(event: 'create', created_at: t0, id: 1),
        version(event: 'update', created_at: t1, deleted_at_change: [nil, t1], id: 2),
      ]
      expect(described_class.reconstruct(versions, record: nil)).to eq([interval(t0, t1)])
    end

    it 'reconstructs a create -> remove -> restore cycle (when restore is versioned) into two intervals' do
      versions = [
        version(event: 'create', created_at: t0, id: 1),
        version(event: 'update', created_at: t1, deleted_at_change: [nil, t1], id: 2),
        version(event: 'update', created_at: t2, deleted_at_change: [t1, nil], id: 3),
      ]
      expect(described_class.reconstruct(versions, record: nil)).to eq([interval(t0, t1), interval(t2, nil)])
    end

    it 'falls back to the record timestamps when there are no versions' do
      record = double(created_at: t0, deleted_at: nil, updated_at: t0)
      expect(described_class.reconstruct([], record: record)).to eq([interval(t0, nil)])
    end

    it 'falls back to a closed interval for a soft-deleted record with no versions' do
      record = double(created_at: t0, deleted_at: t2, updated_at: t2)
      expect(described_class.reconstruct([], record: record)).to eq([interval(t0, t2)])
    end

    it 'reconciles an un-versioned restore: versions end closed but the live row is active' do
      # Mirrors add_viewable, whose restore of a soft-deleted row records NO version.
      versions = [
        version(event: 'create', created_at: t0, id: 1),
        version(event: 'destroy', created_at: t1, id: 2),
      ]
      record = double(created_at: t0, deleted_at: nil, updated_at: t2)
      expect(described_class.reconstruct(versions, record: record)).to eq([interval(t0, t1), interval(t2, nil)])
    end

    it 'reconciles a live row that is currently soft-deleted but whose versions end open' do
      versions = [version(event: 'create', created_at: t0, id: 1)]
      record = double(created_at: t0, deleted_at: t2, updated_at: t2)
      expect(described_class.reconstruct(versions, record: record)).to eq([interval(t0, t2)])
    end
  end

  describe '.covers?' do
    it 'is true within an interval (half-open, inclusive of start)' do
      expect(described_class.covers?([interval(t0, t2)], t0)).to be true
      expect(described_class.covers?([interval(t0, t2)], t1)).to be true
    end

    it 'is false at the exclusive end and outside' do
      expect(described_class.covers?([interval(t0, t2)], t2)).to be false
      expect(described_class.covers?([interval(t0, t2)], t3)).to be false
    end

    it 'treats nil end as extending to infinity' do
      expect(described_class.covers?([interval(t0, nil)], t3)).to be true
    end
  end
end
