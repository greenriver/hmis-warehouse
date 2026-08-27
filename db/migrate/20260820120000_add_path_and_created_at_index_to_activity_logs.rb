###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddPathAndCreatedAtIndexToActivityLogs < ActiveRecord::Migration[7.2]
  # This migration originally added an index directly on `path`, which is unbounded and can exceed
  # Postgres's ~2704 byte btree row limit on some installations. Left as a no-op rather than edited
  # further, since it has already run (successfully or not) in deployed environments; the index it
  # would have built is dropped, and replaced with one on ActivityLog#reporting_path, in
  # db/migrate/20260827150000_add_reporting_path_to_activity_logs.rb.
  def change
  end
end
