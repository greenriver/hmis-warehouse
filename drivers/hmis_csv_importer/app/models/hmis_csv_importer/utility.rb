###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisCsvImporter::Utility
  def self.clear!
    raise 'Refusing to wipe a production warehouse' if Rails.env.production?

    Rails.application.config.hmis_data_lakes.each_value do |module_name|
      module_name.constantize.loadable_files.each do |_, klass|
        klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name} RESTART IDENTITY")
      end
      module_name.constantize.importable_files.each do |_, klass|
        klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name} RESTART IDENTITY")
      end
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
