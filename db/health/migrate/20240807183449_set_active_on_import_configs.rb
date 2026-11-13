###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class SetActiveOnImportConfigs < ActiveRecord::Migration[7.0]
  def up
    Health::ImportConfig.update_all(active: true)
  end
end
