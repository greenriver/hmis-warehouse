module GrdaWarehouse
  class ClientSearchQuery < GrdaWarehouseBase
    belongs_to :user

    def self.find_or_create_by_params(params)
      fingerprint = generate_fingerprint(params)
      where(fingerprint: fingerprint).first_or_create!(params: params)
    end

    private

    def self.generate_fingerprint(params)
      norm = params&.to_h&.reject { |_, v| v.blank? }&.sort.to_h
      Digest::SHA256.hexdigest(norm.to_json)
    end
  end
end
