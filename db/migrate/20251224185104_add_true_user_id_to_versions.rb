###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddTrueUserIdToVersions < ActiveRecord::Migration[7.2]
  def change
    add_column :versions, :true_user_id, :bigint
  end
end
