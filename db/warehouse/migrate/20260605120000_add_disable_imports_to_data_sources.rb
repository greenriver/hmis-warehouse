###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDisableImportsToDataSources < ActiveRecord::Migration[7.2]
  def change
    add_column :data_sources, :disable_imports, :boolean, null: false, default: false
  end
end
