# frozen_string_literal: true

module Hmis
  class ClientSearchQuery < GrdaWarehouseBase
    include ClientSearchQueryShared
    belongs_to :created_by, class_name: 'Hmis::User'

    ALLOWED_PARAMS = [
      'text_search',
      'first_name',
      'last_name',
      'dob',
      'ssn_serial',
      'personal_id',
      # The following search types are not currently used in the frontend,
      # but supported by HmisSchema::ClientSearchInput and tested in rspec, so no harm in keeping them here
      'warehouse_id',
      'projects',
      'organizations',
    ].freeze
  end
end
