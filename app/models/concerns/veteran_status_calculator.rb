###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module VeteranStatusCalculator
  extend ActiveSupport::Concern

  # Calculate veteran status for a destination Client.
  #
  # @param verified_veteran_status [String]
  # @param va_verified_veteran [Boolean]
  # @param source_clients [Array<Hash>] Sources clients are treated as a hash to allow loading outside of ActiveRecprd
  def calculate_best_veteran_status(verified_veteran_status, va_verified_veteran, source_clients)
    # Get the best Veteran status (has 0/1, newest breaks the tie)
    # As of 2/16/2019 calculate using if ever yes, override with verified_veteran_status == non_veteran
    return 0 if verified_veteran_status == 'non_veteran'
    return 1 if va_verified_veteran
    return 1 if source_clients.map { |sc| sc[:VeteranStatus] }.include?(1)

    # Will return No or DK/R/NC
    source_clients.max do |a, b|
      a[:DateUpdated] <=> b[:DateUpdated]
    end[:VeteranStatus]
  end
end
