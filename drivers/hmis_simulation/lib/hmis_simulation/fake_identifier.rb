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
  #   - UUIDs:       FAKExxxx...  (32 chars, no dashes)
  #   - SSNs:        999XXXXXX  (999 prefix is never valid)
  #   - First names: city or water body name + "_"  (e.g. "Portland_", "Tahoe_")
  #   - Last names:  Latin plant binomial + "_"  (e.g. "Quercus robur_")
  module FakeIdentifier
    FAKE_NAMES_DIR = File.expand_path('fake_names', __dir__).freeze

    # Generates a 32-character HUD-style ID (no dashes, matching generate_uuid convention)
    # with a FAKE prefix so it is obviously synthetic at a glance.
    def self.uuid
      "FAKE#{SecureRandom.hex(14)}"
    end

    def self.ssn(rng: nil)
      digits = rng ? format('%06d', rng.rand(1_000_000)) : format('%06d', SecureRandom.random_number(1_000_000))
      "999#{digits}"
    end

    def self.first_name(rng: nil)
      "#{rng ? first_names.sample(random: rng) : first_names.sample}_"
    end

    def self.last_name(rng: nil)
      "#{rng ? last_names.sample(random: rng) : last_names.sample}_"
    end

    def self.first_names
      @first_names ||= File.readlines(File.join(FAKE_NAMES_DIR, 'first_names.txt'), chomp: true).reject(&:blank?)
    end
    private_class_method :first_names

    def self.last_names
      @last_names ||= File.readlines(File.join(FAKE_NAMES_DIR, 'last_names.txt'), chomp: true).reject(&:blank?)
    end
    private_class_method :last_names
  end
end
