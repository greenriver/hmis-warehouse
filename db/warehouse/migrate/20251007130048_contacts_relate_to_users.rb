###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ContactsRelateToUsers < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      add_reference :contacts, :user
      change_column_null :contacts, :email, true
    end
  end
end
