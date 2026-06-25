###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class FixUserAuthenticationSourcesDeletedAt < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      rename_column :user_authentication_sources, :discarded_at, :deleted_at
      remove_index :user_authentication_sources, :deleted_at if index_exists?(:user_authentication_sources, :deleted_at)

      remove_index :user_authentication_sources, [:connector_user_id, :connector_id]
      add_index :user_authentication_sources, [:connector_user_id, :connector_id], unique: true, where: 'deleted_at IS NULL'
    end
  end
end
