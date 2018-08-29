module Health
  class SignatureRequest < HealthBase
    acts_as_paranoid

    belongs_to :signable_document, required: false
    belongs_to :careplan
    has_one :team_member, required: false, class_name: Health::Team::Member.name, primary_key: [:patient_id, :to_email], foreign_key: [:patient_id, :email]

    validates_presence_of :patient_id, :careplan_id, :to_email, :to_name, :requestor_email, :requestor_name, :expires_at
    attr_accessor :team_member_id

    scope :expired, -> do
      where(arel_table[:expires_at].lt(Time.now))
    end

    scope :complete, -> do
      where.not(completed_at: nil)
    end

    scope :sent, -> do
      where.not(sent_at: nil)
    end

    scope :outstanding, -> do
      where(arel_table[:expires_at].gt(Time.now)).
      where(completed_at: nil)
    end

    def self.expires_in
      if Rails.env.development?
        1.hours
      else
        7.days
      end
    end

    def signed?
      completed_at.present?
    end

    def expired?
      expires_at < Time.now
    end

    def complete?
      signed?
    end

    def outstanding?
      ! expired? && ! signed?
    end

    def pcp_request?
      false
    end
    def aco_request?
      false
    end
    def patient_request?
      false
    end
  end
end