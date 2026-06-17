###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddSexToHudAprClients < ActiveRecord::Migration[7.1]
  def change
    add_column :hud_report_apr_clients, :sex, :integer
  end
end
