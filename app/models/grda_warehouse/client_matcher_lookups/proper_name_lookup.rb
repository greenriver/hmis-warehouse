###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::ClientMatcherLookups
  class ProperNameLookup < BaseLookup
    attr_accessor :transliterate
    def initialize(transliterate: false)
      self.transliterate = transliterate
      super()
    end

    def get_ids(first_name:, last_name:)
      first_name = normalize(first_name)
      last_name = normalize(last_name)
      return [] unless first_name && last_name

      key = [first_name, last_name]
      @values[key]&.uniq || []
    end

    def add(client)
      first_name = normalize(client.first_name)
      last_name = normalize(client.last_name)
      return unless first_name && last_name

      key = [first_name, last_name]
      @values[key] ||= []
      @values[key].push(client.id)
    end

    protected

    def normalize(str)
      return nil unless str.present?

      str = I18n.transliterate(str) if transliterate
      str.downcase.strip.gsub(/[^a-z0-9]/, '').presence
    end
  end
end
