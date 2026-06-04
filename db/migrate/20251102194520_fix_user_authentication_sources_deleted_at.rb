###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class FixUserAuthenticationSourcesDeletedAt < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      # Rename discarded_at to deleted_at for paranoia gem compatibility
      rename_column :user_authentication_sources, :discarded_at, :deleted_at
      # Drop old index if it exists and recreate with new column name
      remove_index :user_authentication_sources, :discarded_at if index_exists?(:user_authentication_sources, :discarded_at)

      remove_index :user_authentication_sources, [:connector_user_id, :connector_id]
      add_index :user_authentication_sources, [:connector_user_id, :connector_id], unique: true, where: 'deleted_at IS NULL'
    end
  end
end
