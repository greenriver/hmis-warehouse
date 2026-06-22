###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDeletedAtToCeClientProxies < ActiveRecord::Migration[7.1]
  def change
    add_column :ce_client_proxies, :deleted_at, :datetime
  end
end
