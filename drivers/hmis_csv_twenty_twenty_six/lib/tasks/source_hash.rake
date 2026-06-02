###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

namespace :source_hash do
  desc 'Regenerate the committed db/functions/source_hash_*_v01.sql files from the live 2026 staging schema'
  task generate_functions: :environment do
    generator = HmisCsvTwentyTwentySix::SourceHash::TriggerGenerator
    dir = Rails.root.join('db/functions')
    generator.staging_classes.each do |klass|
      path = dir.join(generator.fx_file_name(klass))
      File.write(path, generator.function_sql(klass))
      puts "wrote #{path.relative_path_from(Rails.root)} (#{generator.hash_columns(klass).size} columns)"
    end
  end
end
