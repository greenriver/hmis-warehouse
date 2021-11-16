###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CasBase < ActiveRecord::Base
  self.abstract_class = true
  connects_to database: { writing: :cas, reading: :cas}

  def self.db_exists?
    return false unless ENV['DATABASE_CAS_DB'].present?

    mem_cache.fetch('cas_db_exists', expires_in: 2.minutes) do
      connection_pool.with_connection(&:active?) rescue false # rubocop:disable Style/RescueModifier
    end
  end

  def self.mem_cache
    @mem_cache ||= ActiveSupport::Cache::MemoryStore.new
  end
end
