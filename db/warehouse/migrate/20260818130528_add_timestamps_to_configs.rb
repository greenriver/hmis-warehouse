###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddTimestampsToConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :configs, :created_at, :datetime
    add_column :configs, :updated_at, :datetime
  end
end
