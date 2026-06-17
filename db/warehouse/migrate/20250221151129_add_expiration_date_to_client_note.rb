###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddExpirationDateToClientNote < ActiveRecord::Migration[7.0]
  def change
    add_column :client_notes, :expiration_date, :date
  end
end
