# frozen_string_literal: true

desc 'One time data migration from app.versions to warehouse.versions'
# rails driver:hmis:migrate_versions_20231121
task migrate_versions_20231121: [:environment] do
  import_scope = GrPaperTrail::Version.where("item_type like ?", "Hmis::Hud::%")
  OneTimeMigration20231121.new.perform(import_scope)
end

class OneTimeMigration20231121
  def perform(import_scope)
    # remove records from previous migration
    GrdaWarehouse::Version.where.not(migrated_app_version_id: nil).delete_all

    # GrdaWarehouse::Version.delete_all if Rails.env.development?
    import_scope.find_in_batches.each do |batch|
      GrdaWarehouse::Version.import!(batch.map { |r| transform_record(r) })
    end
  end

  def transform_record(version)
    result = version.attributes
    # track the previous version
    result['migrated_app_version_id'] = result.delete('id')
    ['object', 'object_changes'].each do |field|
      doc = result.delete(field)
      result[field] = doc.present? ? parse_yaml(doc) : nil
    end
    result
  end

  def parse_yaml(doc)
    YAML.load(
      doc,
      permitted_classes: [Time, Date, Symbol, BigDecimal],
      aliases: true,
    ).except('lock_version')
  end
end
