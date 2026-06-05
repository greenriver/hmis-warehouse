###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'securerandom'

module HmisSimulation
  # Generates obviously-fake identifiers for simulated HUD records.
  #
  # Conventions (all identifiers are recognisably fake at a glance):
  #   - UUIDs:       FAKE-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  #   - SSNs:        999XXXXXX  (999 prefix is never valid)
  #   - First names: city name + "_"  (e.g. "Portland_")
  #   - Last names:  river/water body + "_"  (e.g. "Columbia_")
  module FakeIdentifier
    FAKE_NAMES_DIR = File.expand_path('fake_names', __dir__).freeze

    # Generates a 32-character HUD-style ID (no dashes, matching generate_uuid convention)
    # with a FAKE prefix so it is obviously synthetic at a glance.
    def self.uuid
      hex = SecureRandom.uuid.delete('-')
      "FAKE#{hex[4..]}"
    end

    def self.ssn
      "999#{format('%06d', rand(1_000_000))}"
    end

    def self.first_name(rng: nil)
      "#{rng ? cities.sample(random: rng) : cities.sample}_"
    end

    def self.last_name(rng: nil)
      "#{rng ? rivers.sample(random: rng) : rivers.sample}_"
    end

    def self.cities
      @cities ||= File.readlines(File.join(FAKE_NAMES_DIR, 'cities.txt'), chomp: true).reject(&:blank?)
    end
    private_class_method :cities

    def self.rivers
      @rivers ||= File.readlines(File.join(FAKE_NAMES_DIR, 'rivers.txt'), chomp: true).reject(&:blank?)
    end
    private_class_method :rivers
  end
end
