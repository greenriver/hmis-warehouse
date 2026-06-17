###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddRdsS3IntegrationConfig < ActiveRecord::Migration[7.0]
  def change
    add_column :configs, :rds_s3_integration_role_arn, :string
  end
end
