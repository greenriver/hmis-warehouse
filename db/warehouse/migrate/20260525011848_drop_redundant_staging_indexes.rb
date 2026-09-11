# frozen_string_literal: true

class DropRedundantStagingIndexes < ActiveRecord::Migration[7.2]
  # probably safer to avoid the transaction as an exclusive lock is acquired for each table
  # and not released until the tx commits
  disable_ddl_transaction!

  def up
    return unless Rails.env.development? || Rails.env.test? || Rails.env.staging?

    Dba::StagingIndexDeduplicator.new(table_pattern: 'hmis_2026%', dry_run: false).run!
  end
end
