###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Importer::PendingSet, type: :model do
  let!(:ds) { create :source_data_source }
  let!(:kept) { create :hud_enrollment, data_source_id: ds.id }
  let!(:removed) { create :hud_enrollment, data_source_id: ds.id }
  let!(:deleted) { create :hud_enrollment, data_source_id: ds.id, DateDeleted: 1.day.ago }
  let!(:other) { create :hud_enrollment, data_source_id: ds.id }
  let(:klass) { GrdaWarehouse::Hud::Enrollment }
  subject(:set) { described_class.new(klass) }
  after { set.drop! }

  it 'holds exactly the ids added, including soft-deleted rows, and ignores duplicates' do
    expect(set.add!(klass.with_deleted.where(id: [kept.id, removed.id, deleted.id]))).to eq(3)
    expect(set.add!(klass.with_deleted.where(id: [kept.id]))).to eq(0)
    expect(set.relation.pluck(:id)).to contain_exactly(kept.id, removed.id, deleted.id)
  end

  it 'removes only the matched ids and returns the count' do
    set.add!(klass.with_deleted.where(id: [kept.id, removed.id, deleted.id]))
    expect(set.remove!(klass.where(id: [removed.id, other.id]))).to eq(1)
    expect(set.relation.pluck(:id)).to contain_exactly(kept.id, deleted.id)
  end

  it 'is empty before anything is added' do
    expect(set.relation.to_a).to eq([])
  end

  it 'removes ids given as an array' do
    set.add!(klass.with_deleted.where(id: [kept.id, removed.id]))
    expect(set.remove_ids!([removed.id, other.id])).to eq(1)
    expect(set.relation.pluck(:id)).to contain_exactly(kept.id)
  end

  it 'does not write the warehouse rows' do
    before_xmin = klass.with_deleted.order(:id).pluck(Arel.sql('xmin::text'))
    set.add!(klass.with_deleted)
    set.remove!(klass.where(id: kept.id))
    expect(klass.with_deleted.order(:id).pluck(Arel.sql('xmin::text'))).to eq(before_xmin)
  end

  it 'filters a scope to the ids in the set, soft-deleted included, via id_in_set_sql' do
    set.add!(klass.with_deleted.where(id: [kept.id, deleted.id]))
    expect(klass.with_deleted.where(set.id_in_set_sql).pluck(:id)).to contain_exactly(kept.id, deleted.id)
  end

  it 'matches no rows from id_in_set_sql before anything is added' do
    expect(klass.with_deleted.where(set.id_in_set_sql).pluck(:id)).to eq([])
  end

  it 'reports empty until an id is added and again once the last id is removed' do
    expect(set).to be_empty
    set.add!(klass.where(id: kept.id))
    expect(set).not_to be_empty
    set.remove_ids!([kept.id])
    expect(set).to be_empty
  end

  it 'leaves no temp table behind after drop!' do
    set.add!(klass.with_deleted.where(id: kept.id))
    set.drop!
    count = klass.connection.select_value("SELECT count(*) FROM pg_class WHERE relpersistence = 't' AND relname LIKE 'tmp_pending_%'")
    expect(count).to eq(0)
  end
end
