###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddRequestIdToActivityLog < ActiveRecord::Migration[7.1]
  def change
    add_column :hmis_activity_logs, :request_id, :string
  end
end
