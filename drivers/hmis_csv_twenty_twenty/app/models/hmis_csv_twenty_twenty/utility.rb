###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
