###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class YouthActivityController < ApplicationController
    include AjaxModalRails::Controller

    before_action :set_filter

    def index
      client_ids = []
      client_ids += intakes_in_range.distinct.pluck(:client_id) if @filter.activity_type.empty? || @filter.activity_type.include?('youth_intakes')
      client_ids += dfa_in_range.distinct.pluck(:client_id) if @filter.activity_type.empty? || @filter.activity_type.include?('direct_financial_assistances')
      client_ids += case_management_in_range.distinct.pluck(:client_id) if @filter.activity_type.empty? || @filter.activity_type.include?('case_managements')
      client_ids += follow_ups_in_range.distinct.pluck(:client_id) if @filter.activity_type.empty? || @filter.activity_type.include?('youth_follow_ups')
      client_ids += referrals_in_range.distinct.pluck(:client_id) if @filter.activity_type.empty? || @filter.activity_type.include?('youth_referrals')
      @clients = GrdaWarehouse::Hud::Client.where(id: client_ids).
        preload(
          youth_intakes: [:user],
          case_managements: [:user],
          direct_financial_assistances: [:user],
          youth_referrals: [:user],
          youth_follow_ups: [:user],
        )
    end

    private def activity_types
      {
        'Intakes' => :youth_intakes,
        'Case Notes' => :case_managements,
        'Direct Financial Assistance' => :direct_financial_assistances,
        'Referrals' => :youth_referrals,
      }
    end
    helper_method :activity_types

    private def available_agencies
      Agency.where(
        id: User.where(
          id: GrdaWarehouse::YouthIntake::Base.distinct.pluck(:user_id),
        ).select(:agency_id),
      )
    end
    helper_method :available_agencies

    private def available_users
      User.where(id: GrdaWarehouse::YouthIntake::Base.distinct.pluck(:user_id))
    end
    helper_method :available_users

    private def intakes_in_range
      scope = GrdaWarehouse::YouthIntake::Base.where(updated_at: @filter.range)
      scope = scope.where(user_id: user_ids_at_agency) if @filter.agency_id.present?
      scope = scope.where(user_id: @filter.user_id) if @filter.user_id.present?
      scope
    end

    private def dfa_in_range
      scope = GrdaWarehouse::Youth::DirectFinancialAssistance.where(updated_at: @filter.range)
      scope = scope.where(user_id: user_ids_at_agency) if @filter.agency_id.present?
      scope = scope.where(user_id: @filter.user_id) if @filter.user_id.present?
      scope
    end

    private def case_management_in_range
      scope = GrdaWarehouse::Youth::YouthCaseManagement.where(updated_at: @filter.range)
      scope = scope.where(user_id: user_ids_at_agency) if @filter.agency_id.present?
      scope = scope.where(user_id: @filter.user_id) if @filter.user_id.present?
      scope
    end

    private def follow_ups_in_range
      scope = GrdaWarehouse::Youth::YouthFollowUp.where(updated_at: @filter.range)
      scope = scope.where(user_id: user_ids_at_agency) if @filter.agency_id.present?
      scope = scope.where(user_id: @filter.user_id) if @filter.user_id.present?
      scope
    end

    private def referrals_in_range
      scope = GrdaWarehouse::Youth::YouthReferral.where(updated_at: @filter.range)
      scope = scope.where(user_id: user_ids_at_agency) if @filter.agency_id.present?
      scope = scope.where(user_id: @filter.user_id) if @filter.user_id.present?
      scope
    end

    private def user_ids_at_agency
      User.where(agency_id: @filter.agency_id).pluck(:id)
    end

    private def set_filter
      @filter = ::Filters::DateRange.new(report_params[:filter])
      @filter.activity_type = @filter.activity_type.reject(&:blank?)
    end

    private def report_params
      params.permit(
        filter: [
          :start,
          :end,
          :agency_id,
          :user_id,
          activity_type: [],
        ],
      )
    end
  end
end
