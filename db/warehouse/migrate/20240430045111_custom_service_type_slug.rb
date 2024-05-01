class CustomServiceTypeSlug < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      execute <<~SQL
        ALTER TABLE "Services" ADD COLUMN custom_service_type_slug VARCHAR GENERATED ALWAYS AS (data_source_id::text || ':' || "TypeProvided"::text || ':' || "RecordType"::text) STORED
      SQL
      execute <<~SQL
        ALTER TABLE "CustomServiceTypes" ADD COLUMN slug VARCHAR GENERATED ALWAYS AS (data_source_id::text || ':' || "hud_type_provided"::text ||':'|| "hud_record_type"::text) STORED
      SQL
      execute %{CREATE INDEX idx_custom_service_type_slug ON "CustomServiceTypes" (slug)}
      execute %(VACUUM ANALYZE "Enrollment")
      execute %(VACUUM ANALYZE "CustomServices")
      execute %(VACUUM ANALYZE "Services")
    end
  end

  def down
    safety_assured do
      execute %(ALTER TABLE "Services" DROP COLUMN custom_service_type_slug)
      execute %(ALTER TABLE "CustomServiceTypes" DROP COLUMN slug)
    end
  end
end
