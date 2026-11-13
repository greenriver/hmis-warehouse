###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddClientDemographicColumnsToConfigs < ActiveRecord::Migration[7.2]
  def change
    add_column :configs, :client_demographic_columns, :jsonb
  end
end
