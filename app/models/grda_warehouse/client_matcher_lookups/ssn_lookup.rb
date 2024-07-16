###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::ClientMatcherLookups
  class SSNLookup < BaseLookup
    attr_accessor :format
    def initialize(format: :full)
      raise ArgumentError, "unknown format: #{format}" unless format.in?([:full, :last_four])

      self.format = format
      super()
    end

    def get_ids(ssn:)
      return [] unless valid_ssn?(ssn)

      @values[ssn]&.uniq || []
    end

    def add(client)
      key = client.ssn
      key = key[-4..-1] if key && format == :last_four
      return unless key

      @values[key] ||= []
      @values[key].push(client.id)
    end

    protected

    def valid_ssn?(value)
      case format
      when :last_four
        ::HudUtility2024.valid_last_four_social?(value)
      when :full
        ::HudUtility2024.valid_social?(value)
      end
    end
  end
end
