###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Youth
  class InactiveIntake
    include ArelHelper

    attr_accessor :filter

    def initialize(filter)
      @filter = filter
    end

    def clients
      @clients ||= [].tap do |data|
        open_intakes.preload(:client).find_each do |intake|
          case_mangement = max_case_management_by_client_id[intake.client_id]
          dfa = dfa_by_client_id[intake.client_id]
          referral = referral_by_client_id[intake.client_id]
          follow_up = follow_up_by_client_id[intake.client_id]
          dates = [
            case_mangement,
            dfa,
            referral,
            follow_up,
            intake.engagement_date,
          ].compact
          next if dates.present? && filter.range.overlaps?(dates.min..dates.max)

          data << OpenStruct.new(
            {
              client: intake.client,
              intake: intake,
              case_mangement: case_mangement&.to_date,
              dfa: dfa&.to_date,
              referral: referral&.to_date,
              follow_up: follow_up&.to_date,
              max_date: dates.max&.to_date,
            }
          )
        end
      end.compact.uniq
    end

    private def max_case_management_by_client_id
      @max_case_management_by_client_id ||= case_management_source.group(:client_id).maximum(:updated_at)
    end

    private def dfa_by_client_id
      @dfa_by_client_id ||= dfa_source.group(:client_id).maximum(:updated_at)
    end

    private def follow_up_by_client_id
      @follow_up_by_client_id ||= follow_up_source.group(:client_id).maximum(:updated_at)
    end

    private def referral_by_client_id
      @referral_by_client_id ||= referral_source.group(:client_id).maximum(:updated_at)
    end

    private def open_intakes
      intake_source.joins(:client).open_between(start_date: filter.start, end_date: filter.end)
    end

    private def intake_source
      GrdaWarehouse::YouthIntake::Entry.visible_by?(filter.user)
    end

    private def case_management_source
      GrdaWarehouse::Youth::YouthCaseManagement.visible_by?(filter.user).
        where(client_id: open_intakes.select(:client_id))
    end

    private def dfa_source
      GrdaWarehouse::Youth::DirectFinancialAssistance.visible_by?(filter.user).
        where(client_id: open_intakes.select(:client_id))
    end

    private def follow_up_source
      GrdaWarehouse::Youth::YouthFollowUp.visible_by?(filter.user).
        where(client_id: open_intakes.select(:client_id))
    end

    private def referral_source
      GrdaWarehouse::Youth::YouthReferral.visible_by?(filter.user).
        where(client_id: open_intakes.select(:client_id))
    end

  end
end
