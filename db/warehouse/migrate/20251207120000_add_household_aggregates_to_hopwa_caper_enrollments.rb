# frozen_string_literal: true

class AddHouseholdAggregatesToHopwaCaperEnrollments < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :hopwa_caper_enrollments, bulk: true do |t|
        t.string :household_income_benefit_source_types, array: true
        t.string :household_medical_insurance_types, array: true
      end

      # percent_ami is a numeric code
      change_column :hopwa_caper_enrollments, :percent_ami, :integer, using: 'percent_ami::integer'
    end
  end
end
