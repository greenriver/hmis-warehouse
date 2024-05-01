#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class AddEnrollmentSlugToServices < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      [
        'Enrollment',
        'Services',
        'CustomServices',
      ].each do |table|
        execute <<~SQL
          ALTER TABLE "#{table}" ADD COLUMN enrollment_slug VARCHAR GENERATED ALWAYS AS (data_source_id::text || ':' || "EnrollmentID") STORED
        SQL
        execute %{CREATE INDEX idx_#{table.downcase}_enrollment_slug ON "#{table}" (enrollment_slug)}
      end
    end
  end

  def down
    safety_assured do
      [
        'Enrollment',
        'Services',
        'CustomServices',
      ].each do |table|
        execute %(DROP INDEX idx_#{table.downcase}_enrollment_slug)
        execute %(ALTER TABLE "#{table}" DROP COLUMN enrollment_slug)
      end
    end
  end
end
