###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvTwentyTwenty::Utility
  def self.clear!
    raise 'Refusing to wipe a production warehouse' if Rails.env.production?

    HmisCsvTwentyTwenty::Importer::Importer.importable_files.each do |_, klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name}")
    end

    HmisCsvTwentyTwenty::Loader::Loader.importable_files.each do |_, klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name}")
    end

    [
      HmisCsvTwentyTwenty::Aggregated::Enrollment,
      HmisCsvTwentyTwenty::Aggregated::Exit,
      HmisCsvTwentyTwenty::Loader::LoaderLog,
      HmisCsvTwentyTwenty::Importer::ImporterLog,
      HmisCsvValidation::Base,
    ].each do |klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name}")
    end

    nil
  end
end
