###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importers::HmisAutoMigrate
  def self.available_migrations
    Rails.application.config.hmis_migrations || {}
  end

  def self.add_migration(version, migration)
    migrations = available_migrations
    migrations[version] = migration
    Rails.application.config.hmis_migrations = migrations
  end

  def self.apply_migrations(csv_dir, recursed: false)
    hud_export = AutoEncodingCsv.read("#{csv_dir}/Export.csv", headers: true)&.first&.to_hash || {}
    hud_export.transform_keys!(&:downcase)
    return unless hud_export['exportid'].present? # Make sure it is a HUD export file, otherwise do nothing

    version = hud_export['csvversion'] || '2020' # If there is no CSVVersion, assume it is a 2020
    return if version == '2020' && recursed # We applied a transform, but still have no CSVVersion

    return unless available_migrations.keys.include?(version)

    # Apply available migrations
    Dir.mktmpdir do |source_dir|
      # Copy CSV dir to temp
      FileUtils.cp_r(File.join(csv_dir, '.'), source_dir)
      # Transform temp over the to the CSV dir
      available_migrations[version]&.up(source_dir, csv_dir)
    end
    apply_migrations(csv_dir, recursed: true)
  end
end
