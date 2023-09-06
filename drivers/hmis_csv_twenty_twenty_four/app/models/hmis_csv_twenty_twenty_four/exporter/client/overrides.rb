###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'soundex'
module HmisCsvTwentyTwentyFour::Exporter
  class Client::Overrides
    include ::HmisCsvTwentyTwentyFour::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

    # This method gets called for each row of the kiba export
    # to enable these overrides to be applied outside of the kiba context, the overrides are written as class methods that take
    # an instance of the class, with appropriate preloads and returns an overridden version.
    # in addition, there is a single `apply_overrides` method if you want all of them
    # the `process method` will apply all overrides, and then set primary and foreign keys correctly for export
    def process(row)
      row = self.class.apply_overrides(row, export: @options[:export])

      row
    end

    def self.apply_overrides(row, export:)
      # Don't actually do this, identify duplicates and client cleanup should handle this, just use the destination client
      # row = pick_best_source_client_data(row)
      row = apply_length_limits(row)
      row = apply_hash_status(row, export)
      row = enforce_gender_none(row)
      row = enforce_race_none(row)
      row = enforce_required_fields(row)

      row
    end

    def self.apply_hash_status(row, export)
      return row unless export.hash_status == 4

      row.FirstName = Digest::SHA256.hexdigest(Soundex.new(row.FirstName).soundex) if row.FirstName.present?
      row.LastName = Digest::SHA256.hexdigest(Soundex.new(row.LastName).soundex) if row.LastName.present?
      row.MiddleName = Digest::SHA256.hexdigest(Soundex.new(row.MiddleName).soundex) if row.MiddleName.present?

      if row.SSN.present?
        padded_ssn = row.SSN.rjust(9, 'x')
        last_four =  padded_ssn.last(4)
        digested_ssn = Digest::SHA256.hexdigest(padded_ssn)
        row.SSN = "#{last_four}#{digested_ssn}"
      end
      row
    end

    def self.apply_length_limits(row)
      row.FirstName = row.FirstName[0...50] if row.FirstName
      row.MiddleName = row.MiddleName[0...50] if row.MiddleName
      row.LastName = row.LastName[0...50] if row.LastName
      row.NameSuffix = row.NameSuffix[0...50] if row.NameSuffix

      row
    end

    def self.enforce_gender_none(row)
      # GenderNone should be 99 if it was blank and all other gender columns are blank or 0
      gender_columns = HudUtility2024.gender_fields - [:GenderNone]
      any_genders = gender_columns.map { |c| ! row[c].in?([nil, 0]) }.any?
      row.GenderNone ||= 99 unless any_genders

      row
    end

    def self.enforce_race_none(row)
      # RaceNone should be 99 if it was blank and all other gender columns are blank or 0
      race_columns = HudUtility2024.race_fields - [:RaceNone]
      any_races = race_columns.map { |c| ! row[c].in?([nil, 0]) }.any?
      row.RaceNone ||= 99 unless any_races

      row
    end

    def self.enforce_required_fields(row)
      default_to_dnc = [
        :NameDataQuality,
        :SSNDataQuality,
        :DOBDataQuality,
        :VeteranStatus,
      ]
      default_to_dnc.each do |hud_field|
        row = replace_blank(row, hud_field: hud_field, default_value: 99)
      end

      default_to_no = HudUtility2024.gender_fields - [:GenderNone]
      default_to_no += HudUtility2024.race_fields - [:RaceNone]
      default_to_no.each do |hud_field|
        row = replace_blank(row, hud_field: hud_field, default_value: 0)
      end

      row
    end

    # Loop over source clients in reverse chronological order.
    # If we find better data in previous source clients, use it
    def self.pick_best_source_client_data(row)
      row.source_clients.sort_by(&:DateUpdated).reverse_each do |sc|
        if row.NameDataQuality != 1 && sc.NameDataQuality == 1
          row.NameDataQuality = sc.NameDataQuality
          row.FirstName = sc.FirstName
          row.MiddleName = sc.MiddleName
          row.LastName = sc.LastName
          row.NameSuffix = sc.NameSuffix
        end

        if row.SSNDataQuality != 1 && sc.SSNDataQuality == 1
          row.SSNDataQuality = sc.SSNDataQuality
          row.SSN = sc.SSN
        end

        if row.DOBDataQuality != 1 && sc.DOBDataQuality == 1
          row.DOBDataQuality = sc.DOBDataQuality
          row.DOB = sc.DOB
        end
      end

      row
    end
  end
end
