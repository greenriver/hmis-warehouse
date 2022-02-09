###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class UserClient < GrdaWarehouseBase
    has_paper_trail
    acts_as_paranoid

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    belongs_to :user, optional: true

    validate :date_range

    scope :confidential, -> do
      where(confidential: true)
    end

    scope :non_confidential, -> do
      where(confidential: false)
    end

    scope :active, -> do
      at = arel_table
      where(at[:end_date].gteq(Date.current).or(at[:end_date].eq(nil)))
    end

    scope :expired, -> do
      at = arel_table
      where(at[:end_date].lt(Date.current))
    end

    def expired?
      end_date&.past?
    end

    def active_period
      to = end_date || 'present'
      [start_date, ' - ', to].join
    end

    def self.available_users(user)
      return User.none unless user.can_manage_agency

      if user.can_view_all_user_client_assignments
        User.all.order(:first_name, :last_name)
      else
        user.subordinates
      end
    end

    def self.available_relationships
      [
        'Housing Navigator',
        'Primary Case Manager',
        'Case Manager',
        'Nurse Care Manager',
        'Housing Support Provider',
      ].sort.freeze
    end

    private

    def date_range
      errors.add(:end_date, 'should be after start date') if end_date && start_date && end_date <= start_date
    end
  end
end
