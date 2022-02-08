###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

if ENV['DATABASE_CAS_DB'].present?
  class CasBase < ActiveRecord::Base
    self.abstract_class = true

    connects_to database: { writing: :cas, reading: :cas }

    def self.db_exists?
      mem_cache.fetch('cas_db_exists', expires_in: 2.minutes) do
        connection_pool.with_connection(&:active?) rescue false # rubocop:disable Style/RescueModifier
      end
    end

    def self.mem_cache
      @mem_cache ||= ActiveSupport::Cache::MemoryStore.new
    end
  end

else
  class CasBase
    def self.db_exists?
      false
    end
    class << self
      def has_many(*) # rubocop:disable Naming/PredicateName
        []
      end

      def has_one(*) # rubocop:disable Naming/PredicateName
      end

      def belongs_to(*)
      end

      def respond_to_missing?(name, include_private)
      end

      def method_missing(name, *args)
      end
    end
    def respond_to_missing?(name, include_private)
    end

    def method_missing(name, *args)
    end
  end
end
