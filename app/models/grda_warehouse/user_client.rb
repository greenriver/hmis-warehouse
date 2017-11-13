module GrdaWarehouse
  class UserClient < GrdaWarehouseBase
    has_paper_trail
    acts_as_paranoid
    
    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
    belongs_to :user

    validate :date_range

    scope :confidential, -> do
      where(confidential: true)
    end

    scope :non_confidential, -> do
      where(confidential: false)
    end

    scope :active, -> do
      at = self.arel_table
      where(at[:end_date].gteq(Date.today).or(at[:end_date].eq(nil)))
    end

    scope :expired, -> do
      at= self.arel_table
      where(at[:end_date].lt(Date.today))
    end

    def expired?
      end_date && end_date.past?
    end

    def active_period
      to = end_date || 'present'
      [start_date, ' - ', to].join
    end

    def self.available_users
      User.all
    end

    def self.available_relationships
      [
        'Housing Navigator',
        'Primary Case Manager',
        'Case Manager',
        'Nurse Care Manager',
      ].sort.freeze
    end

    private 

    def date_range
      errors.add(:end_date, "should be in the future.") if expired?
    end

  end
end
