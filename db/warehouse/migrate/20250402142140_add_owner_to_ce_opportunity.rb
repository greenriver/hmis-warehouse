###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddOwnerToCeOpportunity < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_reference :ce_opportunities, :owner, polymorphic: true
    end
  end
end
