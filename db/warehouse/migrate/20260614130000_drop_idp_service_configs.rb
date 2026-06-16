###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# idp_service_configs was originally created in the warehouse DB, but it holds
# IDP service-account credentials that belong to the authentication subsystem
# (alongside users / user_authentication_sources in the app DB). It is being
# recreated there by a single rolled-up migration; this drops the misplaced
# warehouse copy.
#
# Safe to drop without preserving data: the IDP feature is still in progress and
# no config has been created in production.
class DropIdpServiceConfigs < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      drop_table :idp_service_configs, if_exists: true
    end
  end

  # No-op rollback: the table's correct home is now the app DB (see the app-side
  # CreateIdpServiceConfigs migration). Recreating it here would reintroduce the
  # split we're removing.
  def down
  end
end
