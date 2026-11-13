###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RemoveRefuseImportsWithErrors < ActiveRecord::Migration[7.0]
  def change
    safety_assured { remove_column :data_sources, :refuse_imports_with_errors, :boolean, default: false, null: false }
  end
end
