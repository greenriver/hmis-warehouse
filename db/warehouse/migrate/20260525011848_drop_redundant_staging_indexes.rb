# frozen_string_literal: true

class DropRedundantStagingIndexes < ActiveRecord::Migration[7.2]
  def up
    return unless Rails.env.development? || Rails.env.test? || Rails.env.staging?

    Dba::StagingIndexDeduplicator.new(dry_run: false).run!
  end

  def down
    # Indexes can be recreated by running the original schema migrations if needed
  end
end
