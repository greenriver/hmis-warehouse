###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Loader
  class HudKeyRemapper
    # HouseholdID and ResProjectID are cross-file join keys with no HUD file
    # of their own (there's no Household.csv), so no class ever declares
    # them as its hud_key -- they have to be added explicitly.
    JOIN_ONLY_COLUMNS = ['HouseholdID', 'ResProjectID'].freeze

    def self.description
      'Remap all HUD ID columns to stable, de-identified values before loading'
    end

    def self.associated_model
      :"All Files"
    end

    def self.enable
      { pre_process_hooks: { name => true } }
    end

    def self.checked?(data_source)
      data_source[:pre_process_hooks][name] || false
    end

    def self.remap!(source_dir, loadable_files, source_id)
      canonical_columns = (loadable_files.values.map { |klass| klass.hud_key.to_s } + JOIN_ONLY_COLUMNS).to_set

      loadable_files.each do |file_name, klass|
        columns = canonical_columns & klass.hud_csv_headers.map(&:to_s)
        next if columns.empty?

        file = File.join(source_dir, file_name)
        next unless File.exist?(file)

        Tempfile.create do |clean_file|
          CSV.open(clean_file, 'wb') do |csv|
            csv << CSV.parse_line(File.open(file, &:readline))
            CSV.foreach(file, headers: true, header_converters: :downcase) do |row|
              columns.each do |column|
                key = column.downcase
                value = row[key]
                row[key] = remap_value(column, source_id, value) if value.present?
              end
              csv << row
            end
          end
          FileUtils.mv(clean_file, file)
        end
      end
    end

    def self.remap_value(column, source_id, original_value)
      Digest::MD5.hexdigest("#{column}--#{source_id}--#{original_value}")
    end
  end
end
