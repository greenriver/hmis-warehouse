###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisCsvImporter::Utility
  def self.clear!
    raise 'Refusing to wipe a production warehouse' if Rails.env.production?

    HmisCsvImporter::Importer::Importer.importable_files.each do |_, klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name} RESTART IDENTITY")
    end

    HmisCsvImporter::Loader::Loader.loadable_files.each do |_, klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name} RESTART IDENTITY")
    end

    TodoOrDie('Remove the explicit truncation of TwentyTwentySix tables', by: '2025-10-01')
    # TwentyTwentySix is explicitly not included in the importable_files to prevent auto migration
    # before it is fully launched.
    Rails.application.config.hmis_data_lake = 'HmisCsvTwentyTwentySix'
    HmisCsvImporter::Importer::Importer.importable_files.each do |_, klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name} RESTART IDENTITY")
    end

    HmisCsvImporter::Loader::Loader.loadable_files.each do |_, klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name} RESTART IDENTITY")
    end
    Rails.application.config.hmis_data_lake = 'HmisCsvTwentyTwentyFour'

    [
      HmisCsvImporter::Aggregated::Enrollment,
      HmisCsvImporter::Aggregated::Exit,
      HmisCsvImporter::Loader::LoaderLog,
      HmisCsvImporter::Loader::LoadError,
      HmisCsvImporter::Importer::ImporterLog,
      HmisCsvImporter::Importer::ImportError,
      HmisCsvImporter::HmisCsvValidation::Base,
    ].each do |klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name} RESTART IDENTITY")
    end

    nil
  end
end
