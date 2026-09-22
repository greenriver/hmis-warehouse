###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDOBSelectionMethodToConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :configs, :dob_selection_method, :string, default: 'legacy', null: false
  end
end
