###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddPreProcessHooksToDataSources < ActiveRecord::Migration[7.2]
  def change
    add_column :data_sources, :pre_process_hooks, :jsonb, null: false, default: {}
  end
end
