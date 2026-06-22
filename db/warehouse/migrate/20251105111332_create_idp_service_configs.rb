###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateIdpServiceConfigs < ActiveRecord::Migration[7.2]
  def change
    # no-op, was create_table `idp_service_configs` but moved to app db
  end
end
