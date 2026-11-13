###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  # Provides a process-stable hash function for deriving deterministic RNG seeds.
  #
  # Ruby's built-in String#hash is randomized per-process by default (RUBY_HASH_SEED),
  # which makes any simulation seed derived from it non-reproducible across process restarts.
  # stable_hash uses SHA-256 so the same string always produces the same integer.
  module Hashing
    module_function

    def stable_hash(str)
      Digest::SHA256.hexdigest(str.to_s).to_i(16) % (2**62)
    end
  end
end
