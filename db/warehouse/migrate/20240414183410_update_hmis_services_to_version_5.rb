#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class UpdateHmisServicesToVersion5 < ActiveRecord::Migration[6.1]
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
        execute <<~SQL
          CREATE INDEX idx_#{table.downcase}_enrollment_slug ON "#{table}" (enrollment_slug)
        SQL
      end
    end
    update_view :hmis_services, version: 5
  end

  # the scenic gem seems to have trouble rolling back without this
  def down
    update_view :hmis_services, version: 4
    safety_assured do
      [
        'Enrollment',
        'Services',
        'CustomServices',
      ].each do |table|
        execute <<~SQL
          ALTER TABLE "#{table}" DROP COLUMN enrollment_slug
        SQL
      end
    end
  end
end
