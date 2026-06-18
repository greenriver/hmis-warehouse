###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDisableImportsToDataSources < ActiveRecord::Migration[7.2]
  def change
    add_column :data_sources, :disable_imports, :boolean, null: false, default: false
  end
end
