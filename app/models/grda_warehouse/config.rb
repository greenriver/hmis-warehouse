###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class Config < GrdaWarehouseBase
    serialize :client_details, Array

    after_save :invalidate_cache

    def self.available_cas_methods
      {
        'Use Available in CAS flag' => :cas_flag,
        'Use potentially chronic report' => :chronic,
        'Use HUD chronic report' => :hud_chronic,
        'All clients with a release on file' => :release_present,
        'Active clients within range' => :active_clients,
      }
    end

    def self.available_cas_sync_months
      {
        'One Month' => 1,
        'Three Months' => 3,
        'Six Months' => 6,
        'Nine Months' => 9,
        'One Year' => 12,
      }
    end

    def self.available_cas_flag_methods
      {
        'A human should review qualifications' => :manual,
        'Trust the uploaded files' => :file,
      }
    end

    def self.family_calculation_methods
      {
        'At least one adult & child' => :adult_child,
        'More than one person, regardless of age' => :multiple_people,
      }
    end

    def self.available_release_durations
      [
        'Indefinite',
        'One Year',
        'Two Years',
        'Use Expiration Date',
      ]
    end

    def self.available_chronic_definitions
      {
        'Potentially chronic' => :chronics,
        'HUD definition' => :hud_chronics,
      }
    end

    def self.available_vispdat_prioritization_schemes
      {
        'Length of time Homeless' => :length_of_time,
        'Veteran status (100)' => :veteran_status,
        'Vets (100), family (50), youth (25)' => :vets_family_youth,
      }
    end

    def self.available_days_homeless_sources
      {
        'Calculated days homeless' => :days_homeless,
        'Calculated days homeless + verified additional days' => :days_homeless_plus_overrides,
      }
    end

    def self.available_health_emergencies
      {
        'Boston COVID-19' => :boston_covid_19,
        'COVID-19 -- Vaccination Only' => :covid_19_vaccinations_only,
      }
    end

    def self.available_health_emergency_tracings
      {
        'COVID-19' => :covid_19,
      }
    end

    def self.available_encryption_types
      {
        'None' => :none,
        'PII Encrypted' => :pii,
      }
    end

    def self.dv_days
      {
        'Indefinite' => 0,
        'Three Years' => 1095,
        'One Year' => 365,
        'Six months' => 180,
        'Three months' => 90,
        'One month' => 30,
      }
    end

    def self.client_search_available?
      get(:pii_encryption_type).to_sym.in?([:none])
    end

    def self.currrent_health_emergency_tracing_title
      available_health_emergency_tracings.invert[get(:health_emergency_tracing).to_sym] || ''
    end

    def self.current_health_emergency_title
      available_health_emergencies.invert[get(:health_emergency)&.to_sym] || ''
    end

    def self.cas_sync_range
      current_range = get(:cas_sync_months) || 3
      (current_range.months.ago.to_date..Date.current)
    end

    def self.cache_store
      @cache_store ||= begin
        store = ActiveSupport::Cache::MemoryStore.new

        if ENV['RAILS_LOG_TO_STDOUT'].present?
          store.logger = Logger.new($stdout)
        else
          store.logger = Logger.new(Rails.root.join('log/cache.log'))
        end

        store.logger.level = Logger::INFO

        store
      end
    end

    def invalidate_cache
      self.class.invalidate_cache
    end

    def self.invalidate_cache
      cache_store.clear
    end

    def self.get(config)
      cache_store.fetch(config, expires_in: 10.seconds) do
        first_or_create.public_send(config)
      end
    end
  end
end
