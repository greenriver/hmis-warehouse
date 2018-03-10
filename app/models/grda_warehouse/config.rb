module GrdaWarehouse
  class Config < GrdaWarehouseBase
    serialize :client_details, Array

    after_save :invalidate_cache

    def self.available_cas_methods
      {
        'Use Available in CAS flag' => :cas_flag,
        'Use potentially chronic report' => :chronic,
        'All clients with a release on file' => :release_present,
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
      ["Indefinite", "One Year"]
    end

    def invalidate_cache
      self.class.invalidate_cache
    end

    def self.invalidate_cache
      Rails.cache.delete(self.name)
    end

    def self.get(config)
      @settings = Rails.cache.fetch(self.name) do
        self.first_or_create
      end
      @settings.public_send(config)
    end
  end
end