module GrdaWarehouse
  class Config < GrdaWarehouseBase
    after_save :invalidate_cache

    def self.available_cas_methods
      [
        'Use Available in CAS flag',
        'Use potentially chronic report',
      ]
    end

    def invalidate_cache
      self.class.invalidate_cache
    end

    def self.invalidate_cache
      Rails.cache.delete(self.name)
    end

    def self.get(config)
      settings = Rails.cache.fetch(self.name) do
        self.first_or_create
      end
      settings.public_send(config)
    end
  end
end