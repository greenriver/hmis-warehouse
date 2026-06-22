###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddActiveToImportConfig < ActiveRecord::Migration[7.0]
  def change
    add_column :import_configs, :active, :boolean, default: false
  end
end
