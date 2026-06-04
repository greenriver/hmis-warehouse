###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Stub retained so legacy generators (FY2020–FY2024) keep working for read-only drilldowns.
# Field definitions and question mappings now live in DrilldownPresenter.
module HudApr::CellDetailsConcern
  extend ActiveSupport::Concern

  included do
    def self.client_class(_question)
      HudApr::Fy2020::AprClient
    end
  end
end
