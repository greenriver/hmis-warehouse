# frozen_string_literal: true

class AddAtcFieldsToHopwaCaperEnrollments < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :hopwa_caper_enrollments, bulk: true do |t|
        t.boolean :atc_maintained_contact
        t.boolean :atc_housing_plan
        t.boolean :atc_primary_health_contact
      end
    end
  end
end
