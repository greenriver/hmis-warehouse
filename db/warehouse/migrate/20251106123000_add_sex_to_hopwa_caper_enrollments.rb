# frozen_string_literal: true

class AddSexToHopwaCaperEnrollments < ActiveRecord::Migration[7.1]
  def change
    add_column :hopwa_caper_enrollments, :sex, :integer
  end
end
