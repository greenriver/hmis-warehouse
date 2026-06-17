###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class MakeOpportunityProjectIdNullable < ActiveRecord::Migration[7.1]
  def change
    change_column_null :ce_opportunities, :project_id, true
  end
end
