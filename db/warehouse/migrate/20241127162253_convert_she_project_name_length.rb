###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ConvertSheProjectNameLength < ActiveRecord::Migration[7.0]
  def up
    drop_view :service_history
    change_column :service_history_enrollments, :project_name, :string

    create_view :service_history
  end

  def down
    drop_view :service_history
    change_column :service_history_enrollments, :project_name, :string, limit: 150

    create_view :service_history
  end
end
