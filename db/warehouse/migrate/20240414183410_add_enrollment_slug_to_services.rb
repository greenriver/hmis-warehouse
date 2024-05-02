#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class AddEnrollmentSlugToServices < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      [
        ['Enrollment', 'slug'],
        ['Services', 'enrollment_slug'],
        ['CustomServices', 'enrollment_slug'],
      ].each do |table, field|
        execute <<~SQL
          ALTER TABLE "#{table}" ADD COLUMN #{field} VARCHAR GENERATED ALWAYS AS (data_source_id::text || ':' || "EnrollmentID") STORED
        SQL
        execute %(CREATE INDEX idx_#{table.downcase}_enrollment_slug ON "#{table}" (#{field}))
      end
      execute %(CREATE INDEX index_services_hud_types ON public."Services" USING btree ("RecordType", "TypeProvided"))
    end
  end

  def down
    safety_assured do
      [
        ['Enrollment', 'slug'],
        ['Services', 'enrollment_slug'],
        ['CustomServices', 'enrollment_slug'],
      ].each do |table, field|
        execute %(ALTER TABLE "#{table}" DROP COLUMN #{field})
      end
      execute %(DROP INDEX index_services_hud_types)
    end
  end
end
