###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class MakeOpportunityProjectIdNullable < ActiveRecord::Migration[7.1]
  def change
    change_column_null :ce_opportunities, :project_id, true
  end
end
