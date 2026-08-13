###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # The write collides with an account the IdP already holds — under email-as-username realms,
  # the address belongs to somebody else there. Unlike the rest of ServiceError, this is ordinary
  # bad input rather than a broken service, so callers put it on the form instead of paging.
  class ConflictError < ServiceError
  end
end
