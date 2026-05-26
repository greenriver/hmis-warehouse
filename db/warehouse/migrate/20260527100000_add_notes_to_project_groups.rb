###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddNotesToProjectGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :project_groups, :notes, :text
  end
end
