###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddThemeColumnsToPublicReportSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :public_report_settings, :secondary_color, :string
    add_column :public_report_settings, :heading_color, :string
    add_column :public_report_settings, :text_color, :string
    add_column :public_report_settings, :border_color, :string
    add_column :public_report_settings, :surface_tint_color, :string
    add_column :public_report_settings, :focus_color, :string
    add_column :public_report_settings, :map_not_reporting_color, :string
  end
end
