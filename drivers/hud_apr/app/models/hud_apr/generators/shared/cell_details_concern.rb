###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::CellDetailsConcern
  extend ActiveSupport::Concern

  included do
    private def common_headings
      [
        :first_name,
        :last_name,
      ].freeze
    end
    helper_method :common_headings
  end
end
