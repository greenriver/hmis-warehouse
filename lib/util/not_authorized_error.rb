###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# See: docs/domain-pack/authorization/warehouse-policies.md
# See: docs/domain-pack/authorization/warehouse-legacy-roles.md
class NotAuthorizedError < StandardError
  attr_reader :message

  def initialize(message = nil)
    @message = message || 'Sorry you are not authorized to do that.'
    super(@message)
  end
end
