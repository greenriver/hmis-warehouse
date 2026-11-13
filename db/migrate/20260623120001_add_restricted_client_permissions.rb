###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddRestrictedClientPermissions < ActiveRecord::Migration[7.1]
  def up
    ::Hmis::Role.ensure_permissions_exist
    ::Hmis::Role.reset_column_information
  end

  def down
    remove_column :hmis_roles, :can_mark_clients_as_restricted
    remove_column :hmis_roles, :can_view_restricted_clients
  end
end
