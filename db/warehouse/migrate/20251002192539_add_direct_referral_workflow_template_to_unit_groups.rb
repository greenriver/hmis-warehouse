# frozen_string_literal: true

class AddDirectReferralWorkflowTemplateToUnitGroups < ActiveRecord::Migration[7.1]
  def change
    add_column :hmis_unit_groups, :direct_referral_workflow_template_identifier, :string
  end
end
