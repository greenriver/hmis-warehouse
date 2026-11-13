###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DropClaimsReportingTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :claims_reporting_ccs_lookups, if_exists: true
    drop_table :claims_reporting_cp_payment_details, if_exists: true
    drop_table :claims_reporting_cp_payment_uploads, if_exists: true
    drop_table :claims_reporting_engagement_trends, if_exists: true
    drop_table :claims_reporting_imports, if_exists: true
    drop_table :claims_reporting_medical_claims, if_exists: true
    drop_table :claims_reporting_member_diagnosis_classifications, if_exists: true
    drop_table :claims_reporting_member_enrollment_rosters, if_exists: true
    drop_table :claims_reporting_member_rosters, if_exists: true
    drop_table :claims_reporting_quality_measures, if_exists: true
    drop_table :claims_reporting_rx_claims, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
