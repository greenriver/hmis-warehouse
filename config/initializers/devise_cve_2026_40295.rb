###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Backport fix for CVE-2026-40295 (GHSA-jp94-3292-c3xv):
# Open redirect via unvalidated `request.referrer` in Timeoutable session timeout handler.
# https://github.com/heartcombo/devise/security/advisories/GHSA-jp94-3292-c3xv
# https://github.com/heartcombo/devise/commit/025fe2124f9928766fc46520e999633b598d0360
#
# Safe to remove once Devise is removed entirely.

TodoOrDie('Remove CVE-2026-40295 monkey patch', if: !defined?(Devise))

module DeviseStoreLocationPatch
  private

  def extract_path_from_location(location)
    uri = parse_uri(location)

    return unless uri&.path

    path = remove_domain_from_uri(uri)
    path = add_fragment_back_to_path(uri, path)

    path
  end
end

module DeviseFailureAppPatch
  protected

  def redirect_url
    if warden_message == :timeout
      flash[:timedout] = true if is_flashing_format?

      path = if request.get?
        attempted_path
      else
        extract_path_from_location(request.referrer)
      end

      path || scope_url
    else
      scope_url
    end
  end
end

Devise::Controllers::StoreLocation.prepend(DeviseStoreLocationPatch)
Devise::FailureApp.prepend(DeviseFailureAppPatch)
