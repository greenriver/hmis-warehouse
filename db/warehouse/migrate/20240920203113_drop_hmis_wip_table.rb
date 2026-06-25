###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DropHmisWipTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :hmis_wips
  end
end
