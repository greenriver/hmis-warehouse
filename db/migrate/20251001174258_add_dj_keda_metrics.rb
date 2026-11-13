###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDjKedaMetrics < ActiveRecord::Migration[7.1]
  def change
    create_view 'puma_scaling_login_demand'
  end
end
