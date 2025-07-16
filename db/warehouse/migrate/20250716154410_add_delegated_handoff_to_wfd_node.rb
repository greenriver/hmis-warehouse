###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDelegatedHandoffToWfdNode < ActiveRecord::Migration[7.1]
  def change
    # "Delegated handoff" is a flag indicating this node should be handed off to another process as part of the workflow.
    # For example, in a Referral workflow, this would be a UserTask node that is delegated to the referring Project.
    add_column :wfd_nodes, :delegated_handoff, :boolean, null: false, default: false
  end
end

# rails db:migrate:up:warehouse VERSION=20250716154410
# rails db:migrate:down:warehouse VERSION=20250716154410
