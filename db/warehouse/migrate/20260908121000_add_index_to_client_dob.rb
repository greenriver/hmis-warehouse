###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddIndexToClientDOB < ActiveRecord::Migration[8.1]
  def change
    # Omit `algorithm: :concurrently`, so the migration runs in one transaction.
    # This avoids needing disable_ddl_transaction! which we've had issues with in the past.
    safety_assured do
      add_index(
        :Client,
        :DOB,
        name: :idx_client_dob,
      )
    end
  end
end
