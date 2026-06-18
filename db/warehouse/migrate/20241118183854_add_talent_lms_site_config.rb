###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddTalentLmsSiteConfig < ActiveRecord::Migration[7.0]
  def change
    add_column :configs, :number_lms_courses_required, :integer, default: -1
  end
end
