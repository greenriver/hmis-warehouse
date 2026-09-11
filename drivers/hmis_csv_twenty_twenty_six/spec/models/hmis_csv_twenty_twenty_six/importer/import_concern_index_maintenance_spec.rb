###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentySix::Importer::ImportConcern, '.ensure_importer_log_id_date_updated_index!' do
  # CREATE INDEX CONCURRENTLY cannot run inside the per-example transaction, so this group manages
  # the indexes itself and restores them afterwards to leave the test database as structure.sql defines it.
  self.use_transactional_tests = false

  let(:test_class) { HmisCsvTwentyTwentySix::Importer::HealthAndDv }
  let(:connection) { test_class.connection }
  let(:composite_index_name) { test_class.importer_log_id_date_updated_index_name }
  let(:importer_log_id_index_name) { "index_#{test_class.table_name}_on_importer_log_id" }
  let(:date_updated_index_name) { test_class.table_name.gsub(/[^0-9a-z ]/i, '') + '_' + Digest::MD5.hexdigest('DateUpdated')[0, 4] }

  def restore_original_indexes
    connection.remove_index(test_class.table_name, name: composite_index_name) if connection.index_name_exists?(test_class.table_name, composite_index_name)
    connection.add_index(test_class.table_name, :importer_log_id, name: importer_log_id_index_name) unless connection.index_name_exists?(test_class.table_name, importer_log_id_index_name)
    connection.add_index(test_class.table_name, :DateUpdated, name: date_updated_index_name) unless connection.index_name_exists?(test_class.table_name, date_updated_index_name)
  end

  before { restore_original_indexes }
  after { restore_original_indexes }

  it 'builds the composite importer_log_id, DateUpdated index' do
    expect { test_class.ensure_importer_log_id_date_updated_index! }.
      to change { connection.index_name_exists?(test_class.table_name, composite_index_name) }.from(false).to(true)
  end

  it 'drops the standalone importer_log_id index once the composite index exists' do
    expect { test_class.ensure_importer_log_id_date_updated_index! }.
      to change { connection.index_name_exists?(test_class.table_name, importer_log_id_index_name) }.from(true).to(false)
  end

  it 'drops the standalone DateUpdated index once the composite index exists' do
    expect { test_class.ensure_importer_log_id_date_updated_index! }.
      to change { connection.index_name_exists?(test_class.table_name, date_updated_index_name) }.from(true).to(false)
  end

  it 'leaves an existing valid composite index in place' do
    test_class.ensure_importer_log_id_date_updated_index!

    expect { test_class.ensure_importer_log_id_date_updated_index! }.
      not_to change { connection.index_name_exists?(test_class.table_name, composite_index_name) }.from(true)
  end
end
