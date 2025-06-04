###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Importers::HmisAutoMigrate
  # This method allows us to prevent auto migrating data past a specific version.
  # Specifically, it allow us to support import of a newer version, but deployment
  # prior to the release of the new version.
  # NOTE: There is similar logic in spec/support/hmis_csv_fixtures.rb to control test behavior.
  TodoOrDie('Update stop_version after FY2026 changeover', by: '2025-11-01')
  # For now, prevent migrating beyond 2024 version
  def self.current_stop_version
    return nil if Date.current >= '2025-10-01'.to_date
    return nil if Date.current >= '2025-09-01'.to_date && Rails.env.staging?

    # Default to the current version, but allow for override in development
    ENV.fetch('HMIS_AUTOMIGRATE_STOP_VERSION', '2026')
  end

  # available_migrations is a hash of version strings seen in HUD exports to migration classes
  def self.available_migrations
    Rails.application.config.hmis_migrations || {}
  end

  def self.add_migration(version, migration)
    migrations = available_migrations
    migrations[version] = migration
    Rails.application.config.hmis_migrations = migrations
  end

  # Applies the appropriate migrations to transform HMIS CSV data to the latest format
  #
  # @param csv_dir [String] Path to directory containing CSV files to migrate
  # @param notifier [Object, nil] Notification service that responds to #ping (optional)
  # @param recursed [Boolean] Whether this is a recursive call from within the method
  # @param stop_version [String, nil] Optional version to stop migrating at (used for testing)
  # @return [String] The normalized version of the CSV data
  # @note Migrations are applied sequentially as needed by copying files to a temporary
  #   directory, transforming them, and then copying back to the original location
  def self.apply_migrations(csv_dir, notifier, recursed: false, stop_version: nil)
    version = calculate_current_version(csv_dir)
    # The stop version is used for testing to prevent migrating beyond the expected version
    return version if version == stop_version
    return version if version == '2020' && recursed # We applied a transform, but still have no CSVVersion

    # Don't allow migrating to 2026 on production before 10/1/2025
    # Don't allow migrating to 2026 on staging before 9/1/2025
    TodoOrDie('Remove the next lines to enable migration to 2026', by: '2025-11-01')
    return version if version.in?(['2024', '2026']) && Date.current < '2025-10-01'.to_date && Rails.env.production?
    return version if version.in?(['2024', '2026']) && Date.current < '2025-09-01'.to_date && Rails.env.staging?

    return version unless available_migrations.keys.include?(version)

    puts "Migrating format from #{version}"
    notifier&.ping "Migrating format from #{version}"
    # Apply available migrations
    Dir.mktmpdir do |source_dir|
      # Copy CSV dir to temp
      FileUtils.cp_r(File.join(csv_dir, '.'), source_dir)
      # Transform temp over the to the CSV dir
      available_migrations[version]&.constantize&.up(source_dir, csv_dir)
    end
    apply_migrations(csv_dir, notifier, recursed: true, stop_version: stop_version)
  end

  def self.calculate_current_version(file_path)
    hud_export = AutoEncodingCsv.read("#{file_path}/Export.csv", headers: true)&.first.to_h
    hud_export.transform_keys!(&:downcase)
    raise "Unknown HMIS CSV version for file #{file_path}" unless hud_export['exportid'].present? # Make sure it is a HUD export file, otherwise do nothing

    normalize_version(hud_export['csvversion']) || '2020'
  end

  def self.normalize_version(version)
    # Short circuit for 2026, we don't have anything newer, so there are no migrations for it
    return '2026' if version&.include?('2026')

    transformer_name = available_migrations[version]
    return unless transformer_name.present?

    if transformer_name.include?('HudTwentyTwentyFourToTwentyTwentySix')
      '2024'
    elsif transformer_name.include?('HudTwentyTwentyTwoToTwentyTwentyFour')
      '2022'
    end
  end
end
