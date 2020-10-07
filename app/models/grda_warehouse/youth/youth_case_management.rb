###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Youth
  class YouthCaseManagement < GrdaWarehouseBase
    include ArelHelper
    include YouthExport

    after_save :create_required_follow_up!
    after_save :complete_required_follow_up!

    has_paper_trail
    acts_as_paranoid

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :case_managements
    belongs_to :user
    has_many :youth_intakes, through: :client
    has_many :youth_follow_ups, through: :client

    validates_presence_of :engaged_on, :activity

    scope :ordered, -> do
      order(engaged_on: :desc)
    end

    scope :between, ->(start_date:, end_date:) do
      at = arel_table
      where(at[:engaged_on].gteq(start_date).and(at[:engaged_on].lteq(end_date)))
    end

    scope :visible_by?, ->(user) do
      # users at your agency, plus your own user in case you have no agency.
      agency_user_ids = User.
        with_deleted.
        where.not(agency_id: nil).
        where(agency_id: user.agency_id).
        pluck(:id) + [user.id]
      if user.can_edit_anything_super_user?
        all
      # If you can see any, then show yours, those for your agency, and those for anyone with a full release
      elsif user.can_view_youth_intake? || user.can_edit_youth_intake?
        where(
          arel_table[:client_id].in(Arel.sql(GrdaWarehouse::Hud::Client.full_housing_release_on_file.select(:id).to_sql)).
          or(arel_table[:user_id].in(agency_user_ids)),
        )
      # If you can see your agency's, then show yours and those for your agency
      elsif user.can_view_own_agency_youth_intake? || user.can_edit_own_agency_youth_intake?
        where(user_id: agency_user_ids)
      else
        none
      end
    end

    def self.current_generic_housing_status(on_date: Date.current)
      record = ordered.where(arel_table[:engaged_on].lt(on_date)).limit(1)&.first
      return [] unless record.present?

      [
        record.engaged_on,
        generic_housing_status(record.housing_status),
      ]
    end

    def self.generic_housing_status(status)
      if status == at_risk_string
        :at_risk
      elsif status == stably_housed_string
        :housed
      else
        :other
      end
    end

    def self.at_risk_string
      'This youth is currently at risk'
    end

    def self.stably_housed_string
      'This youth is currently in stable housing'
    end

    # Follow-ups are required 90 days after:
    # 1. The first time a youth identified as at risk for losing housing
    # 2. A youth reports having moved from a non-housed situation to housing
    def create_required_follow_up!
      return if youth_follow_ups.incomplete.exists?

      action = self.class.generic_housing_status(housing_status)
      return unless action
      return unless transitioning_to_at_risk? || transitioning_to_housing?

      options = {
        client_id: client_id,
        user_id: user_id,
        action_on: engaged_on,
        required_on: GrdaWarehouse::Youth::YouthFollowUp.follow_up_date(engaged_on),
        action: action,
      }
      GrdaWarehouse::Youth::YouthFollowUp.create(options)
    end

    def complete_required_follow_up!
      due_follow_up = youth_follow_ups.due.first
      return unless due_follow_up

      due_follow_up.update(
        housing_status: self.class.generic_housing_status(housing_status),
        zip_code: zip_code,
        contacted_on: engaged_on,
        case_management_id: id,
      )
    end

    private def transitioning_to_housing?
      stably_housed? && client.current_youth_housing_situation(on_date: engaged_on) != :housed
    end

    private def transitioning_to_at_risk?
      at_risk_of_homelessness? && client.current_youth_housing_situation(on_date: engaged_on).in?([nil, :housed])
    end

    private def at_risk_of_homelessness?
      housing_status == at_risk_string
    end

    private def at_risk_string
      self.class.at_risk_string
    end

    private def stably_housed?
      housing_status == stably_housed_string
    end

    private def stably_housed_string
      self.class.stably_housed_string
    end

    def self.youth_housing_status_options
      [
        'This youth is currently in stable housing',
        'This youth is currently experiencing homeless',
        'This youth is currently at risk',
        'This youth is not currently in stable housing',
        'Unknown',
        'Other:',
      ]
    end

    def self.available_activities
      [
        'Prevention ',
        'Re-Housing',
      ]
    end
  end
end
