# frozen_string_literal: true

module GrdaWarehouse
  class ClientSearchQuery < GrdaWarehouseBase
    belongs_to :user

    def self.find_or_create_by_params!(params)
      norm = normalize_params(params.to_h)
      fingerprint = generate_fingerprint(norm)
      where(fingerprint: fingerprint).first_or_create!(params: norm)
    end

    def self.generate_fingerprint(params)
      Digest::SHA256.hexdigest(params.to_json)
    end

    def self.normalize_params(params)
      return {} if params.nil?

      params.transform_values do |v|
        case v
        when Hash
          normalize_params(v)
        when String
          v.strip
        else
          v
        end
      end.reject { |_, v| v.blank? }.sort.to_h
    end
  end
end
