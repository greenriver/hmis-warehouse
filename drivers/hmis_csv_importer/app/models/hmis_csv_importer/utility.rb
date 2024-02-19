###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::Utility
  def self.clear!
    raise 'Refusing to wipe a production warehouse' if Rails.env.production?

    HmisCsvImporter::Importer::Importer.importable_files.each do |_, klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name} RESTART IDENTITY")
    end

    HmisCsvImporter::Loader::Loader.loadable_files.each do |_, klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name} RESTART IDENTITY")
    end

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
