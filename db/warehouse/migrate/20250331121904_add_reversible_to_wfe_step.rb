###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddReversibleToWfeStep < ActiveRecord::Migration[7.0]
  def change
    add_column :wfe_steps, :reversible, :boolean, null: false, default: true
  end
end
