###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis
  module AhaScores
    AhaResult = Data.define(:score, :mci_quality_indicator, :dw_client_id, :generator)
    MhAhaResult = Data.define(:score, :dw_client_id, :generator)
    VisionLinkResult = Data.define(
      :score,
      :dw_client_id,
      :generator,
      :is_eligible_ra,
      :section_8,
      :city_of_pittsburgh,
      :subsidized_housing,
      :recent_eviction_case,
    )
  end
end
