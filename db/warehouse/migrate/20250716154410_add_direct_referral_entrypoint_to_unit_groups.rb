###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDirectReferralEntrypointToUnitGroups < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      add_reference :hmis_unit_groups, :direct_referral_entrypoint, foreign_key: { to_table: :wfd_nodes }, null: true
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20250716154410
# rails db:migrate:down:warehouse VERSION=20250716154410
