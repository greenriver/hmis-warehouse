###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddClientRetentionYears < ActiveRecord::Migration[7.2]
  def change
    add_column :configs, :client_retention_years, :integer
    add_column :data_sources, :client_retention_years, :integer
  end
end
