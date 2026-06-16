###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateIdpServiceConfigs < ActiveRecord::Migration[7.2]
  def change
    # no-op, was create_table `idp_service_configs` but moved to app db
  end
end
