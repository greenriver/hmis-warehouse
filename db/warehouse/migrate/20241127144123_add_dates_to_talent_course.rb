###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDatesToTalentCourse < ActiveRecord::Migration[7.0]
  def change
    add_column :talentlms_courses, :start_date, :date
    add_column :talentlms_courses, :end_date, :date
  end
end
