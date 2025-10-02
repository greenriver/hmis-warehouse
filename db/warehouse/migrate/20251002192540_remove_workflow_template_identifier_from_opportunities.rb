# frozen_string_literal: true

class RemoveWorkflowTemplateIdentifierFromOpportunities < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :ce_opportunities, :workflow_template_identifier, :string }
  end
end
