###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RemoveCredentialsFromUsers < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      remove_column :users, :credentials, :string
    end
  end
end
