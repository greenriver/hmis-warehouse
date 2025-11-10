###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RemoveWorkflowTemplateIdentifierFromOpportunities < ActiveRecord::Migration[7.1]
  def change
    # safety_assured because we added this column to Hmis::Ce::Opportunity.ignored_columns in the previous release.
    safety_assured { remove_column :ce_opportunities, :workflow_template_identifier, :string }
  end
end
