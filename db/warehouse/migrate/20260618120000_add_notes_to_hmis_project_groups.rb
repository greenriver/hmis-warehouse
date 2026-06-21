###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddNotesToHmisProjectGroups < ActiveRecord::Migration[7.1]
  def change
    add_column :hmis_project_groups, :notes, :text
  end
end
