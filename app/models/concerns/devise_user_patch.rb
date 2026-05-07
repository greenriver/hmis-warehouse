###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module DeviseUserPatch
  extend ActiveSupport::Concern
  included do
    TodoOrDie('Remove devise patch for CVE-2026-32700', if: !defined?(Devise))
  end

  # patch CVE-2026-32700, avoids upgrading from 4 to 5. Remove this after we migrate to SSO
  protected def postpone_email_change_until_confirmation_and_regenerate_confirmation_token
    unconfirmed_email_will_change!
    super
  end
end
