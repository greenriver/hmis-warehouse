###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class MakeOpportunityWorkflowTemplateIdentifierNullable < ActiveRecord::Migration[7.1]
  def change
    change_column_null :ce_opportunities, :workflow_template_identifier, true
  end
end
