###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDescriptionAndOwnerToCohort < ActiveRecord::Migration[7.2]
  def change
    add_column :cohorts, :description, :text
    add_column :cohorts, :owner_id, :bigint
  end
end
