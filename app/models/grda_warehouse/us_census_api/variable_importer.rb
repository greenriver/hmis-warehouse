###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#
# Code initially written for and funded by Delaware Health and Social Services.
# Used and modified with permission.
#
# The Census provides lists of the variables available. We ingest them with this class.

module GrdaWarehouse
  module UsCensusApi
    class VariableImporter
      attr_accessor :year, :dataset

      def initialize(year:, dataset:)
        require 'curb'

        self.year = year
        self.dataset = dataset
      end

      def run!
        _groups!
        _variables!
      end

      def _variables!
        return if CensusVariable.where(year: self.year, dataset: self.dataset).any?

        Rails.logger.info "Getting census variables for #{self.dataset} for #{self.year}"

        lookup_url =
          if self.dataset.match?(/acs/)
            "https://api.census.gov/data/#{self.year}/acs/#{self.dataset}/variables.json"
          elsif self.dataset.match?(/sf\d/)
            "https://api.census.gov/data/#{self.year}/dec/#{self.dataset}/variables.json"
            else
              raise "dataset we didn't account for found"
            end

        vars = []
        begin
          vars = JSON.parse(Curl.get(lookup_url).body)['variables']
        rescue JSON::ParserError => e
          Rails.logger.error e.message
        end

        records = []
        vars.each do |name, values|
          records << {
            year: self.year,
            dataset: self.dataset,
            name: name,
            label: values['label'],
            concept: values['concept']||'none',
            census_group: values['group'],
            census_attributes: values['attributes']||'none'
          }
        end

        CensusVariable.import(records, on_duplicate_key_update: ['year', 'dataset', 'name'], raise_error: true)
      end

      def _groups!
        return if CensusGroup.where(year: self.year, dataset: self.dataset).any?

        Rails.logger.info "Getting census groups for #{self.dataset} for #{self.year}"

        lookup_url =
          if self.dataset.match?(/acs/)
            "https://api.census.gov/data/#{self.year}/acs/#{self.dataset}/groups.json"
          elsif self.dataset.match?(/sf\d/)
            "https://api.census.gov/data/#{self.year}/dec/#{self.dataset}/groups.json"
            else
              raise "dataset we didn't account for found"
            end

        groups = []
        begin
          groups = JSON.parse(Curl.get(lookup_url).body)['groups']
        rescue JSON::ParserError => e
          Rails.logger.error e.message
        end

        records = []
        groups.each do |values|
          records << {
            year: self.year,
            dataset: self.dataset,
            name: values['name'],
            description: values['description']
          }
        end

        CensusGroup.import(records, on_duplicate_key_update: ['name', 'dataset', 'year'], raise_error: true)
      end
    end
  end
end
