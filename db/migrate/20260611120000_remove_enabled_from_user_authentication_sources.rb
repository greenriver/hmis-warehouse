###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RemoveEnabledFromUserAuthenticationSources < ActiveRecord::Migration[7.1]
  def change
    # The enabled flag added in SsoImplementation carried no behavior worth
    # keeping (severed links are modeled by soft-delete). safety_assured: the
    # column and its only references ship together on this unreleased branch.
    safety_assured do
      remove_column :user_authentication_sources, :enabled, :boolean, default: true, null: false
    end
  end
end
