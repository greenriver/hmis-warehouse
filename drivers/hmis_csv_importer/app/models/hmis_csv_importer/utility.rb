###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::Utility
  def self.clear!
    raise 'Refusing to wipe a production warehouse' if Rails.env.production?

    HmisCsvImporter::Importer::Importer.importable_files.each do |_, klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name}")
    end

    HmisCsvImporter::Loader::Loader.importable_files.each do |_, klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name}")
    end

    [
      HmisCsvImporter::Aggregated::Enrollment,
      HmisCsvImporter::Aggregated::Exit,
      HmisCsvImporter::Loader::LoaderLog,
      HmisCsvImporter::Importer::ImporterLog,
      HmisCsvImporter::HmisCsvValidation::Base,
    ].each do |klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name}")
    end

    nil
  end
end
