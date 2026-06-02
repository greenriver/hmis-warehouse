# frozen_string_literal: true

class DropRedundantStagingIndexes < ActiveRecord::Migration[7.2]
  # probably safer to avoid the transaction an exclusive lock is acquired for each table
  # and not released until the tx commits
  disable_ddl_transaction!

  def up
    return unless Rails.env.development? || Rails.env.test? || Rails.env.staging?

    Dba::StagingIndexDeduplicator.new(dry_run: false).run!
  end
end
