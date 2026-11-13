###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# A user may hold only one live identity link per connector.
#
class AddUniqueLiveUserConnectorToUserAuthenticationSources < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      add_index :user_authentication_sources, [:user_id, :connector_id],
                unique: true,
                name: 'index_user_auth_sources_on_user_connector_live',
                where: 'deleted_at IS NULL'
    end
  end
end
