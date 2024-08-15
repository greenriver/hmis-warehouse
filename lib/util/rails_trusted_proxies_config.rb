###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'ipaddr'

module RailsTrustedProxiesConfig
  # @param [string] trusted_proxies_str CSV, for example "4.4.4.4, 8.8.8.0/24"
  # @returns [(String|IPaddr)]
  def self.parse_csv(trusted_proxies_str)
    return unless trusted_proxies_str.present?

    single_ip_patterns = [
      ::IPAddr::RE_IPV4ADDRLIKE,
      ::IPAddr::RE_IPV6ADDRLIKE_FULL,
      ::IPAddr::RE_IPV6ADDRLIKE_COMPRESSED,
    ]

    trusted_proxies = trusted_proxies_str.split(',').map do |str|
      str.strip!
      next unless str.present?

      single_ip_patterns.any? { |regex| str =~ regex } ? str : IPAddr.new(str)
    end
    trusted_proxies.compact.presence
  end
end
