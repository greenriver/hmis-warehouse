###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# `configs` lives in the warehouse database (see db/warehouse_structure.sql).
# Stored as text to match `client_details`; the array-ness comes from
# `serialize type: Array` in GrdaWarehouse::Config, not from the column type.
# Intentionally no default and no backfill: an empty value means "use the
# columns the demographic table renders today".
class AddClientDemographicColumnsToConfigs < ActiveRecord::Migration[7.2]
  def change
    add_column :configs, :client_demographic_columns, :text
  end
end
