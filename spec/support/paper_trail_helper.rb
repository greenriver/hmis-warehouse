###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Provides a single place to suspend or re-enable PaperTrail so specs and
# long-running tasks can wrap their work without sprinkling manual
# `PaperTrail.enabled =` assignments throughout the codebase. The helpers always
# restore the previous state, letting nested calls behave as expected.
#
# Examples:
#   PaperTrailHelper.without_paper_trail { perform_import }
#   PaperTrailHelper.with_paper_trail { PaperTrail.request.enabled = true }
module PaperTrailHelper
  class << self
    def without_paper_trail(&block)
      around_paper_trail(false, &block)
    end

    def with_paper_trail(&block)
      around_paper_trail(true, &block)
    end

    private

    def around_paper_trail(enable)
      previous = PaperTrail.enabled?
      PaperTrail.enabled = enable
      yield
    ensure
      PaperTrail.enabled = previous
    end
  end
end
