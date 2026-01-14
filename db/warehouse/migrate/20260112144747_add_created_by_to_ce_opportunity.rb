###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddCreatedByToCeOpportunity < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      # created_by_id refers to the users table, but no foreign key constraint
      # because users are in a different database boundary (app db vs warehouse db)
      add_reference :ce_opportunities, :created_by, null: true, index: false
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20260112144747
# rails db:migrate:down:warehouse VERSION=20260112144747
