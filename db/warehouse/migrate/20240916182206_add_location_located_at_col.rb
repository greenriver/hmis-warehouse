###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddLocationLocatedAtCol < ActiveRecord::Migration[7.0]
  def change
    add_column :clh_locations, :located_at, :datetime, required: false
  end
end
