###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Filters
  class ClientLookup < FilterBase
    # This report has no CoC picker, so CoC codes must not contribute to project scoping.
    # Otherwise FilterBase#update's multi-CoC auto-default would expand effective_project_ids
    # even when the user selected nothing, defeating the guard in ClientLookupsController.
    def effective_project_ids_from_coc_codes
      []
    end
  end
end
