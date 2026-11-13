###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UpdateTalentConfigRecords < ActiveRecord::Migration[7.0]
  def up
    Talentlms::Config.all.each do |c|
      c.update(default: true, configuration_name: c.subdomain)
    end
  end
end
