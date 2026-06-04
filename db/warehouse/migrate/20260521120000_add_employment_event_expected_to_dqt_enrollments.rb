# frozen_string_literal: true

class AddEmploymentEventExpectedToDqtEnrollments < ActiveRecord::Migration[7.2]
  def change
    add_column :hmis_dqt_enrollments, :employment_event_expected, :boolean
  end
end
