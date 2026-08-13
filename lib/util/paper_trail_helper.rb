###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Provides a single place to suspend or re-enable PaperTrail so specs and
# long-running tasks can wrap their work without sprinkling manual
# `PaperTrail.enabled =` / `PaperTrail.request.enabled =` assignments throughout
# the codebase. PaperTrail gates recording on both switches together: the global
# `PaperTrail.enabled` (thread-wide) and the per-request `PaperTrail.request.enabled`
# (backed by RequestStore, which specs never clear between examples). Toggling only
# one leaves the other's last value stuck for whatever runs next, so these helpers
# always manage both as a pair and restore their previous values, letting nested
# calls behave as expected.
#
# Examples:
#   PaperTrailHelper.without_paper_trail { perform_import }
#   PaperTrailHelper.enable
#   PaperTrailHelper.restore(previous)
module PaperTrailHelper
  class << self
    def without_paper_trail(&block)
      around_paper_trail(false, &block)
    end

    def with_paper_trail(&block)
      around_paper_trail(true, &block)
    end

    def enable
      adjust_enabled(true)
    end

    def restore(state)
      PaperTrail.enabled = state[:enabled]
      PaperTrail.request.enabled = state[:request_enabled]
    end

    private

    def around_paper_trail(enable)
      previous = adjust_enabled(enable)
      yield
    ensure
      restore(previous)
    end

    def adjust_enabled(value)
      previous = { enabled: PaperTrail.enabled?, request_enabled: PaperTrail.request.enabled? }
      PaperTrail.enabled = value
      PaperTrail.request.enabled = value
      previous
    end
  end
end
