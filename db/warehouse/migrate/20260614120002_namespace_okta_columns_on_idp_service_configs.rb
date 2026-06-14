###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Aligns the provider-specific tenancy columns with Okta's vocabulary, the same way
# keycloak_realm is namespaced, so they don't read as the HMIS Project/Organization
# entities:
#
#   org_id → okta_org_id  — (Okta) org identifier; Okta's tenant unit
#
# project_id is dropped: it was a holdover (Okta has no "project" concept) and has
# no readers. These columns have no consumers yet (Okta integration is pending and
# won't have API access), so the rename + drop is safe — no running code references
# the old names.
class NamespaceOktaColumnsOnIdpServiceConfigs < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      rename_column :idp_service_configs, :org_id, :okta_org_id
      remove_column :idp_service_configs, :project_id, :string
    end
  end
end
