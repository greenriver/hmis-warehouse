###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class Careplan < HealthBase
    acts_as_paranoid

    phi_patient :patient_id
    phi_attr :id, Phi::OtherIdentifier
    phi_attr :user_id, Phi::SmallPopulation
    phi_attr :sdh_enroll_date, Phi::SmallPopulation
    phi_attr :first_meeting_with_case_manager_date, Phi::Date
    phi_attr :self_sufficiency_baseline_due_date, Phi::Date
    phi_attr :self_sufficiency_final_due_date, Phi::Date
    phi_attr :self_sufficiency_baseline_completed_date, Phi::Date
    phi_attr :self_sufficiency_final_completed_date, Phi::Date
    phi_attr :patient_signed_on, Phi::Date
    phi_attr :provider_signed_on, Phi::Date
    phi_attr :initial_date, Phi::Date
    phi_attr :patient_health_problems, Phi::FreeText
    phi_attr :patient_strengths, Phi::FreeText
    phi_attr :patient_goals, Phi::FreeText
    phi_attr :patient_barriers, Phi::FreeText
    phi_attr :responsible_team_member_id, Phi::SmallPopulation
    phi_attr :provider_id, Phi::SmallPopulation
    phi_attr :representative_id, Phi::SmallPopulation
    phi_attr :responsible_team_member_signed_on, Phi::Date
    phi_attr :representative_signed_on, Phi::Date
    phi_attr :service_archive, Phi::FreeText
    phi_attr :equipment_archive, Phi::FreeText
    phi_attr :team_members_archive, Phi::FreeText
    phi_attr :patient_signature_requested_at, Phi::Date
    phi_attr :provider_signature_requested_at, Phi::Date
    phi_attr :health_file_id, Phi::OtherIdentifier

    # has_many :goals, class_name: Health::Goal::Base.name
    # has_many :hpc_goals, class_name: Health::Goal::Hpc.name
    has_one :team, class_name: Health::Team.name, dependent: :destroy

    # PT story #158636393 taken off the of the careplan and added to the patient
    # has_many :team_members, through: :team, source: :members
    belongs_to :patient, class_name: Health::Patient.name
    belongs_to :user

    has_one :health_file, class_name: 'Health::CareplanFile', foreign_key: :parent_id, dependent: :destroy
    include HealthFiles

    has_many :services, through: :patient, class_name: Health::Service.name
    has_many :equipments, through: :patient, class_name: Health::Equipment.name
    has_many :team_members, through: :patient, class_name: Health::Team::Member.name
    has_many :hpc_goals, through: :patient, class_name: Health::Goal::Hpc.name

    has_many :aco_signature_requests, class_name: Health::SignatureRequests::AcoSignatureRequest.name

    # PCP
    has_many :pcp_signature_requests, class_name: Health::SignatureRequests::PcpSignatureRequest.name
    has_many :pcp_signed_signature_requests, -> do
      merge(Health::SignatureRequest.complete)
    end, class_name: Health::SignatureRequests::PcpSignatureRequest.name
    has_many :pcp_signable_documents, through: :pcp_signature_requests, source: :signable_document
    has_many :pcp_signed_documents, -> do
      merge(Health::SignableDocument.signed.with_document)
    end, through: :pcp_signed_signature_requests, source: :signable_document
    has_many :pcp_signed_health_files, through: :pcp_signed_documents, source: :health_files

    # Patient
    has_many :patient_signature_requests, class_name: Health::SignatureRequests::PatientSignatureRequest.name
    has_many :patient_signed_signature_requests, -> do
      merge(Health::SignatureRequest.complete)
    end, class_name: Health::SignatureRequests::PatientSignatureRequest.name
    has_many :patient_signable_documents, through: :patient_signature_requests, source: :signable_document
    has_many :patient_signed_documents, -> do
      merge(Health::SignableDocument.signed.with_document)
    end, through: :patient_signed_signature_requests, source: :signable_document
    has_many :patient_signed_health_files, through: :patient_signed_documents, source: :health_files

    belongs_to :responsible_team_member, class_name: Health::Team::Member.name
    belongs_to :provider, class_name: Health::Team::Member.name
    belongs_to :representative, class_name: Health::Team::Member.name

    has_many :signable_documents, as: :signable
    has_one :primary_signable_document, -> do
      where(signable_documents: {primary: true})
    end, class_name: Health::SignableDocument.name, as: :signable

    serialize :service_archive, Array
    serialize :equipment_archive, Array
    serialize :team_members_archive, Array
    serialize :goals_archive, Array

    validates_presence_of :provider_id, if: -> { self.provider_signed_on.present? }

    # Scopes
    scope :locked, -> do
      where(locked: true)
    end
    scope :editable, -> do
      where(locked: false)
    end

    scope :approved, -> do
      where(status: :approved)
    end
    scope :rejected, -> do
      where(status: :rejected)
    end
    scope :sorted, -> do
      order(id: :desc, initial_date: :desc, updated_at: :desc)
    end

    scope :pcp_signed, -> do
      where.not(provider_signed_on: nil)
    end
    scope :patient_signed, -> do
      where.not(patient_signed_on: nil)
    end
    scope :fully_signed, -> do
      pcp_signed.patient_signed
    end

    scope :recent, -> do
      order(provider_signed_on: :desc).limit(1)
    end
    scope :active, -> do
      fully_signed.where(arel_table[:provider_signed_on].gteq(12.months.ago))
    end
    scope :expired, -> do
      where(arel_table[:provider_signed_on].lt(12.months.ago))
    end
    scope :expiring_soon, -> do
      where(provider_signed_on: 12.months.ago..11.months.ago)
    end
    scope :recently_signed, -> do
      active.where(arel_table[:provider_signed_on].gteq(1.months.ago))
    end
    scope :after_enrollment_date, -> do
      joins(patient: :patient_referral).
      where(arel_table[:provider_signed_on].gteq(hpr_t[:enrollment_start_date]))
    end

    # End Scopes

    # if the care plan has been signed, return the health file id associated with the most
    # recent signature
    # if it hasn't been signed at all, return nil
    def most_appropriate_pdf_id
      pcp_sig = pcp_signature_requests.complete.order(completed_at: :desc).limit(1).first
      patient_sig = patient_signature_requests.complete.order(completed_at: :desc).limit(1).first
      return nil if pcp_sig.blank? && patient_sig.blank?
      most_recently_signed = [pcp_sig, patient_sig].compact.max{|a,b| a.completed_at <=> b.completed_at}
      most_recently_signed&.signable_document&.health_file_id
    end

    def editable?
      ! locked
    end

    def import_team_members
      patient.import_epic_team_members
    end

    # We need both signatures, and one of must have just been assigned
    def just_signed?
      (self.patient_signed_on.present? && self.provider_signed_on.present?) && (self.patient_signed_on_changed? || self.provider_signed_on_changed?)
    end

    def set_lock
      if self.patient_signed_on.present? || self.provider_signed_on.present?
        self.locked = true
        archive_services
        archive_equipment
        archive_goals
        archive_team_members
      else
        self.locked = false
      end
      self.save
    end

    def archive_services
      self.service_archive = self.services.map(&:attributes)
    end

    def archive_equipment
      self.equipment_archive = self.equipments.map(&:attributes)
    end

    def archive_goals
      self.goals_archive = self.hpc_goals.map(&:attributes)
    end

    def archive_team_members
      self.team_members_archive = self.team_members.map(&:attributes)
    end

    def revise!

      new_careplan = self.class.new(revsion_attributes)
      self.class.transaction do
        new_careplan.locked = false
        new_careplan.service_archive = nil
        new_careplan.equipment_archive = nil
        new_careplan.goals_archive = nil
        new_careplan.team_members_archive = nil
        new_careplan.save!
      end
      return new_careplan.id
    end

    def revsion_attributes
      attributes = self.attributes.except('id', 'patient_signed_on', 'responsible_team_member_signed_on', 'representative_signed_on', 'provider_signed_on')
      attributes['initial_date'] = Date.current
      attributes['review_date'] = Date.current + 12.months
      return attributes
    end

    def expires_on
      return unless completed?
      ([
        provider_signed_on,
        patient_signed_on
      ].compact.max + 12.months).to_date
    end

    def active?
      completed? && expires_on >= Date.current
    end

    def completed?
      provider_signed_on && patient_signed_on
    end
  end
end