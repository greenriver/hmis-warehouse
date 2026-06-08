###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
