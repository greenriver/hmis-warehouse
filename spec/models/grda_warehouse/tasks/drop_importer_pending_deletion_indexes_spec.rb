###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::DropImporterPendingDeletionIndexes do
  # DROP INDEX CONCURRENTLY can't run inside the per-example transaction. This group recreates
  # the indexes before each example and drops them afterwards, leaving the test database as
  # structure.sql defines it (listed indexes absent, enrollment_export_id present).
  self.use_transactional_tests = false

  let(:connection) { GrdaWarehouseBase.connection }
  let(:kept_index) { 'enrollment_export_id' }

  def index_exists?(name)
    connection.select_value("SELECT to_regclass(#{connection.quote("public.\"#{name}\"")}) IS NOT NULL")
  end

  def create_indexes
    described_class::INDEXES.each do |index|
      column = index[:name] == 'Enrollment_634d' ? :ExportID : :pending_date_deleted
      connection.add_index(index[:table], column, name: index[:name], if_not_exists: true)
    end
    connection.add_index(:Enrollment, :ExportID, name: kept_index, if_not_exists: true)
  end

  before { create_indexes }
  after { described_class.run! }

  it 'drops every listed index' do
    expect(described_class::INDEXES.map { |index| index_exists?(index[:name]) }).to all(be(true))

    described_class.run!

    expect(described_class::INDEXES.map { |index| index_exists?(index[:name]) }).to all(be(false))
  end

  it 'keeps enrollment_export_id when dropping its duplicate Enrollment_634d' do
    described_class.run!

    expect(index_exists?('Enrollment_634d')).to be(false)
    expect(index_exists?(kept_index)).to be(true)
  end

  it 'can run again once the indexes are gone' do
    described_class.run!
    described_class.run!

    expect(described_class::INDEXES.map { |index| index_exists?(index[:name]) }).to all(be(false))
    expect(index_exists?(kept_index)).to be(true)
  end

  it 'drops nothing while another run holds the lock' do
    locked = Queue.new
    release = Queue.new
    holder = Thread.new do
      GrdaWarehouseBase.connection_pool.with_connection do
        GrdaWarehouseBase.with_advisory_lock(described_class::LOCK_NAME) do
          locked << true
          release.pop
        end
      end
    end
    expect(locked.pop(timeout: 10)).to be(true)

    described_class.run!

    expect(described_class::INDEXES.map { |index| index_exists?(index[:name]) }).to all(be(true))
  ensure
    release << true
    holder.join
  end
end
