###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddFy2026Columns < ActiveRecord::Migration[7.1]
  def change
    add_column :Client, :Sex, :integer
    add_column :Enrollment, :MentalHealthConsultation, :integer
    add_column :Services, :InformationDate, :date
  end
end
