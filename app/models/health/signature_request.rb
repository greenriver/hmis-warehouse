###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class SignatureRequest < HealthBase
    acts_as_paranoid

    phi_patient :patient_id

    phi_attr :to_email, Phi::Email
    phi_attr :to_name, Phi::Name
    phi_attr :requestor_email, Phi::Email
    phi_attr :requestor_name, Phi::Name
    phi_attr :expires_at, Phi::Date
    phi_attr :sent_at, Phi::Date
    phi_attr :completed_at, Phi::Date
    phi_attr :signable_document_id, Phi::OtherIdentifier

    belongs_to :signable_document, optional: true
    belongs_to :careplan, optional: true
    has_one :team_member, required: false, class_name: 'Health::Team::Member', primary_key: [:patient_id, :to_email], foreign_key: [:patient_id, :email]

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
