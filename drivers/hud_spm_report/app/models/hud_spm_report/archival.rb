###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport
  module Archival
    extend ActiveSupport::Concern

    included do
      ::HudReportArchival.register_archival_generator(title, self)
    end
  end
end
