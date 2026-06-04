###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# System specs make many requests in-process (Capybara), and HMIS auth uses
# `Hmis::User.cached_user_find` which is memoized (Memery) for 30 seconds.
# If a spec mutates roles/permissions mid-example, the next request can reuse the
# same `Hmis::User` instance and keep stale `@permissions`.
#
# This is test-only: it forces the next request to re-fetch a fresh user instance.
module HmisSystemUserCache
  def clear_hmis_cached_user_find
    Hmis::User.clear_memery_cache! if defined?(Hmis::User) && Hmis::User.respond_to?(:clear_memery_cache!)
    User.clear_memery_cache! if defined?(User) && User.respond_to?(:clear_memery_cache!)
  end
end

RSpec.configure do |config|
  config.include HmisSystemUserCache, type: :system

  # Ensure each system example starts with a clean user lookup cache.
  config.before(:each, type: :system) do
    clear_hmis_cached_user_find
  end
end
