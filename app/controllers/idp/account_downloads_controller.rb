###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Recent Downloads is auth-agnostic; it forks under JWT only so its own index view can render the
# JWT tabs partial (which drops the IdP-owned password/2FA/login-history tabs) instead of the
# Devise one. The listing behavior is inherited unchanged; view lookup falls back to the shared
# account_downloads templates via the inherited controller prefixes.
class Idp::AccountDownloadsController < ::AccountDownloadsController
end
