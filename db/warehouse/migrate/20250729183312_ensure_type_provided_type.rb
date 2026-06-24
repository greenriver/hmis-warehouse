###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class EnsureTypeProvidedType < ActiveRecord::Migration[7.1]
  def up
    safety_assured do
      change_column :hopwa_caper_services, :type_provided, :integer, using: 'type_provided::integer'
    end
  end
end
