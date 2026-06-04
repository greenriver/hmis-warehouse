###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared context for tests that require a real cache store instead of :null_store
#
# Test environment uses :null_store by default which doesn't persist data.
# This is necessary for features that depend on cache persistence between requests,
# such as impersonation state management.
#
# Usage:
#   RSpec.describe SomeController, type: :request do
#     include_context 'with cache store'
#     # ... tests that need cache persistence
#   end
RSpec.shared_context 'with cache store' do
  around do |example|
    original_cache_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original_cache_store
  end
end
