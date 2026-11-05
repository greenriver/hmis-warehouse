###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::BuildFilesAndEnrollmentIndexes do
  # CREATE INDEX CONCURRENTLY can't run inside the per-example transaction, so this group manages
  # the indexes itself and drops them afterwards, leaving the test database as structure.sql defines it.
  self.use_transactional_tests = false

  let(:connection) { GrdaWarehouseBase.connection }
  let(:files_index_name) { 'index_files_on_client_id' }
  let(:enrollment_index_name) { 'idx_enrollment_on_lower_household_id_pattern' }

  def index_validity(name)
    sql = <<~SQL
      SELECT i.indisvalid
      FROM pg_index i
      JOIN pg_class c ON c.oid = i.indexrelid
      WHERE c.relname = #{connection.quote(name)}
    SQL
    connection.select_value(sql)
  end

  def index_oid(name)
    connection.select_value("SELECT #{connection.quote(name)}::regclass::oid")
  end

  def index_definition(name)
    connection.select_value("SELECT pg_get_indexdef(#{connection.quote(name)}::regclass)")
  end

  def drop_indexes
    described_class::INDEXES.each do |index|
      next unless connection.index_name_exists?(index[:table], index[:name])

      connection.remove_index(index[:table], name: index[:name])
    end
  end

  before { drop_indexes }
  after { drop_indexes }

  it 'builds the files client_id index' do
    expect { described_class.run! }.to change { index_validity(files_index_name) }.from(nil).to(true)
    expect(index_definition(files_index_name)).to include('ON public.files USING btree (client_id)')
  end

  it 'builds the partial lower(HouseholdID) text_pattern_ops index on Enrollment' do
    expect { described_class.run! }.to change { index_validity(enrollment_index_name) }.from(nil).to(true)

    definition = index_definition(enrollment_index_name)
    expect(definition).to include('lower(("HouseholdID")::text) text_pattern_ops')
    expect(definition).to include('WHERE ("DateDeleted" IS NULL)')
  end

  it 'leaves existing valid indexes in place' do
    described_class.run!
    original_oids = [files_index_name, enrollment_index_name].map { |name| index_oid(name) }

    described_class.run!

    expect([files_index_name, enrollment_index_name].map { |name| index_oid(name) }).to eq(original_oids)
  end

  it 'rebuilds an invalid index left by a failed concurrent build' do
    is_superuser = connection.select_value('SELECT rolsuper FROM pg_roles WHERE rolname = current_user')
    skip 'marking an index invalid requires a superuser' unless is_superuser

    described_class.run!
    connection.execute(<<~SQL)
      UPDATE pg_index SET indisvalid = false
      WHERE indexrelid = #{connection.quote(enrollment_index_name)}::regclass
    SQL

    expect { described_class.run! }.to change { index_validity(enrollment_index_name) }.from(false).to(true)
  end
end
