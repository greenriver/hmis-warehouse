###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonProjectScorecard
  module RacialEquity
    extend ActiveSupport::Concern
    included do
      def barrier_id_process_score
        return unless barrier_id_process.present?
        return 4 if barrier_id_process?

        0
      end

      def plan_to_address_barriers_score
        return unless plan_to_address_barriers.present?
        return 4 if plan_to_address_barriers?

        0
      end
    end
  end
end
