###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

      # Convert to UTF-8 if we received as anything else as I18n.transliterate expects UTF-8
      # This conversion will strip weirdly encoded characters silently
      str = str.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: '') unless str.encoding == Encoding::UTF_8

      str = I18n.transliterate(str) if transliterate
      str.downcase.strip.gsub(/[^a-z0-9]/, '').presence
    end
  end
end
