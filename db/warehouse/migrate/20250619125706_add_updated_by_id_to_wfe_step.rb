###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddUpdatedByIdToWfeStep < ActiveRecord::Migration[7.1]
  def change
    # This refers to the users table in the app db (not warehouse), so fk relationship is not made explicitly
    add_reference :wfe_steps, :updated_by, null: true, index: false
  end
end
