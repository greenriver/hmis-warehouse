###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Youth
  class FollowUpsReport
    include ArelHelper

    attr_accessor :cut_off_date, :late_date

    def initialize(end_date, user:)
      @end_date = end_date
      @cut_off_date = @end_date - 2.months - 3.weeks
      @late_date = @end_date - 3.months
      @current_user = user
    end

    def clients
      ids_for_seen = intake_source.where(engagement_date: @cut_off_date .. @end_date).pluck(:client_id) +
        GrdaWarehouse::Youth::YouthCaseManagement.visible_by?(@current_user).where(engaged_on: @cut_off_date .. @end_date).pluck(:client_id) +
        GrdaWarehouse::Youth::DirectFinancialAssistance.visible_by?(@current_user).where(provided_on: @cut_off_date .. @end_date).pluck(:client_id) +
        GrdaWarehouse::Youth::YouthReferral.visible_by?(@current_user).where(referred_on: @cut_off_date .. @end_date).pluck(:client_id) +
        GrdaWarehouse::Youth::YouthFollowUp.visible_by?(@current_user).where(contacted_on: @cut_off_date .. @end_date).pluck(:client_id)

      GrdaWarehouse::Hud::Client.joins(:youth_intakes).
        merge(intake_source.open_between(start_date: @cut_off_date, end_date: @end_date)).
        merge(intake_source.visible_by?(@current_user)).
        merge(GrdaWarehouse::Youth::YouthCaseManagement.visible_by?(@current_user)).
        merge(GrdaWarehouse::Youth::DirectFinancialAssistance.visible_by?(@current_user)).
        merge(GrdaWarehouse::Youth::YouthReferral.visible_by?(@current_user)).
        merge(GrdaWarehouse::Youth::YouthFollowUp.visible_by?(@current_user)).
        includes(
          :case_managements,
          :direct_financial_assistances,
          :youth_referrals,
          :youth_follow_ups
        ).
        references(
          :case_managements,
          :direct_financial_assistances,
          :youth_referrals,
          :youth_follow_ups
        ).
        where.not(id: ids_for_seen).
        distinct.
        pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.
        sort_by { |row| row[:last_seen] }
    end

    def columns
      {
        id: :id,
        first_name: :FirstName,
        last_name: :LastName,
        engagement_date: :engagement_date,
        # GREATEST is not supported on SQL Server, so to work there, this would need to be abstracted
        last_seen: 'GREATEST(engagement_date, provided_on, referred_on, contacted_on, engaged_on)',
      }
    end

    def intake_source
      GrdaWarehouse::YouthIntake::Entry
    end
  end
end
