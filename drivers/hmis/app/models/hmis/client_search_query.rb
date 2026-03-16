# frozen_string_literal: true

module Hmis
  class ClientSearchQuery < GrdaWarehouseBase
    include ClientSearchQueryShared
    belongs_to :created_by, class_name: 'Hmis::User'

    ALLOWED_PARAMS = ['text_search'].freeze
    # todo @martha
    # ALLOWED_PARAMS = ['q', 'client'].freeze
    # ALLOWED_CLIENT_PARAMS = ['first_name', 'last_name', 'dob', 'ssn'].freeze
  end
end
