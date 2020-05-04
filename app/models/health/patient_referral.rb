###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class PatientReferral < HealthBase
    include PatientReferralImporter
    include ArelHelper

    phi_patient :patient_id

    phi_attr :first_name, Phi::Name
    phi_attr :last_name, Phi::Name
    phi_attr :birthdate, Phi::Date
    phi_attr :ssn, Phi::Ssn
    phi_attr :medicaid_id, Phi::HealthPlan
    # phi_attr  :agency_id
    # phi_attr  :rejected
    # phi_attr :rejected_reason
    phi_attr :accountable_care_organization_id, Phi::OtherIdentifier
    phi_attr :effective_date, Phi::Date
    phi_attr :middle_initial, Phi::Name
    phi_attr :suffix, Phi::Name
    # phi_attr :gender
    # phi_attr :aco_name, Phi::NeedsReview
    # phi_attr :aco_mco_pid, Phi::NeedsReview
    # phi_attr :aco_mco_sl, Phi::NeedsReview
    phi_attr :health_plan_id, Phi::OtherIdentifier
    phi_attr :cp_assignment_plan, Phi::NeedsReview
    phi_attr :cp_name_dsrip, Phi::NeedsReview
    phi_attr :cp_name_official, Phi::NeedsReview
    # phi_attr :cp_pid, Phi::NeedsReview
    # phi_attr :cp_sl, Phi::NeedsReview
    phi_attr :enrollment_start_date, Phi::Date
    phi_attr :start_reason_description, Phi::FreeText
    phi_attr :address_line_1, Phi::Location
    phi_attr :address_line_2, Phi::Location
    phi_attr :address_city, Phi::Location
    phi_attr :address_zip, Phi::Location
    phi_attr :address_zip_plus_4, Phi::Location
    # phi_attr :address_state, Phi::Location # this is OK on its own
    phi_attr :email, Phi::Email
    phi_attr :phone_cell, Phi::Telephone
    phi_attr :phone_day, Phi::Telephone
    phi_attr :phone_night, Phi::Telephone
    # phi_attr :primary_language
    phi_attr :primary_diagnosis, Phi::SmallPopulation
    phi_attr :secondary_diagnosis, Phi::SmallPopulation
    phi_attr :pcp_last_name, Phi::SmallPopulation
    phi_attr :pcp_first_name, Phi::SmallPopulation
    phi_attr :pcp_npi, Phi::SmallPopulation
    phi_attr :pcp_address_line_1, Phi::Location
    phi_attr :pcp_address_line_2, Phi::Location
    phi_attr :pcp_address_city, Phi::Location
    # phi_attr :pcp_address_state
    phi_attr :pcp_address_zip, Phi::Location
    phi_attr :pcp_address_phone, Phi::SmallPopulation
    phi_attr :dmh, Phi::NeedsReview
    phi_attr :dds, Phi::NeedsReview
    phi_attr :eoea, Phi::NeedsReview
    phi_attr :ed_visits, Phi::NeedsReview
    phi_attr :snf_discharge, Phi::NeedsReview
    phi_attr :identification, Phi::LicenceNumber #Phi::NeedsReview ??
    # phi_attr :record_status
    phi_attr :record_updated_on, Phi::Date
    phi_attr :exported_on, Phi::Date
    # phi_attr :removal_acknowledge
    phi_attr :disenrollment_date, Phi::Date
    phi_attr :stop_reason_description, Phi::FreeText

    before_validation :update_rejected_from_reason

    # rejected_reason_none: 0 always needs to be there
    # this is the default and means that the patient referral is not rejected
    enum rejected_reason: {
      Remove_Removal: 0,
      Declined: 1,
      Unreachable: 2,
      Moved_out_of_Geographic_Area: 3,
      Graduated: 4,
      Enrollee_requested_change: 5,
      'ACO/MCO requested change' => 6,
      Medical_exception: 8,
      Reported_Eligibility_Loss: 9,
      Disengaged: 10,
      Deceased: 7,
    }

    # The current referral for a patient is their most recent
    scope :current, -> { where(current: true) }

    # The contributing referrals for a patient are the referrals to consider when counting enrollment days
    scope :contributing, -> { where(contributing: true) }

    # Scopes for the current referral
    scope :assigned, -> { current.where(rejected: false).where.not(agency_id: nil) }
    scope :unassigned, -> { current.where(rejected: false).where(agency_id: nil) }
    scope :rejected, -> { current.where(rejected: true) }
    scope :not_rejected, -> { current.where(rejected: false) }
    scope :with_patient, -> { current.where.not patient_id: nil }
    scope :rejection_confirmed, -> { current.where(removal_acknowledged: true) }
    scope :not_confirmed_rejected, -> { current.where(removal_acknowledged: false) }
    scope :pending_disenrollment, -> { current.where.not(pending_disenrollment_date: nil) }

    scope :active_within_range, -> (start_date:, end_date:) do
      at = arel_table
      # Excellent discussion of why this works:
      # http://stackoverflow.com/questions/325933/determine-whether-two-date-ranges-overlap
      d_1_start = start_date
      d_1_end = end_date
      d_2_start = at[:enrollment_start_date]
      d_2_end = at[:disenrollment_date]
      # Currently does not count as an overlap if one starts on the end of the other
      where(d_2_end.gteq(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lteq(d_1_end)))
    end
    scope :referred_on, -> (date) do
      where(enrollment_start_date: date)
    end

    scope :at_acos, -> (aco_ids) do
      where(accountable_care_organization_id: aco_ids)
    end

    validates_presence_of :first_name, :last_name, :birthdate, :medicaid_id
    validates_size_of :ssn, is: 9, allow_blank: true

    has_many :relationships, class_name: 'Health::AgencyPatientReferral', dependent: :destroy
    has_many :relationships_claimed, -> do
      merge(Health::AgencyPatientReferral.claimed)
    end, class_name: 'Health::AgencyPatientReferral'
    has_many :relationships_unclaimed, -> do
      merge(Health::AgencyPatientReferral.unclaimed)
    end, class_name: 'Health::AgencyPatientReferral'
    belongs_to :assigned_agency, class_name: 'Health::Agency', foreign_key: :agency_id
    belongs_to :patient, optional: true
    belongs_to :aco, class_name: 'Health::AccountableCareOrganization', foreign_key: :accountable_care_organization_id

    def self.create_referral(patient, args)
      referral_args = args.merge(current: true, contributing: true)
      if patient.present?
        # Re-enrollment
        current_referral = patient.patient_referral
        enrollment_start_date = referral_args[:enrollment_start_date]
        last_enrollment_date = current_referral.disenrollment_date
        if last_enrollment_date.nil?
          # Last referral was not disenrolled. For record keeping, close the last enrollment, and immediately open a new one
          current_referral.update(disenrollment_date: enrollment_start_date, current: false)
        else
          if (enrollment_start_date - last_enrollment_date).to_i > 90
            # It has been more than 90 days, so this is a "reenrollment"
            patient.patient_referrals.contributing.update_all(current: false, contributing: false)
          else
            # This is an "auto-reenrollment"
            current_referral.update(current: false, contributing: true)
          end
        end
      end
      referral = create(referral_args)
      referral.convert_to_patient

      referral
    end

    def client
      patient&.client
    end

    accepts_nested_attributes_for :relationships

    def update_rejected_from_reason
      if self.rejected_reason_none?
        self.rejected = false
      else
        self.rejected = true
      end
      return true
    end

    def relationship_to(agency)
      relationships.select{|r| r.agency_id == agency.id}&.last
    end

    def assigned?
      agency_id.present?
    end

    def engagement_date
      return nil unless enrollment_start_date.present?

      next_month = enrollment_start_date.at_beginning_of_month.next_month
      if enrollment_start_date < '2018-09-01'.to_date
        (next_month + 120.days).to_date
      else
        (next_month + 90.days).to_date
      end
    end

    def careplan_signed_in_122_days?
      return false unless enrollment_start_date

      careplan_date = patient&.qualifying_activities&.
        after_enrollment_date&.
        submittable&.
        where(activity: :pctp_signed)&.
        minimum(:date_of_activity)

      (careplan_date - enrollment_start_date).to_i <= 122
    end

    def name
      "#{first_name} #{last_name}"
    end

    def age
      if birthdate.present?
        GrdaWarehouse::Hud::Client.age(dob: birthdate.to_date, date: Date.current)
      else
        'Unknown'
      end
    end

    def rejected_reason_none?
      rejected_reason == 'Remove_Removal'
    end

    def self.display_rejected_reason(reason)
      reason.gsub('_', ' ')
    end

    # Valid values
    # Not Yet Started
    # In Process
    # Engaged
    # Unreachable/Unable to Contact
    # Declined Participation
    # Deceased
    def outreach_status
      # outreach status needs to include patient values including some from patients that may have been deleted
      if patient.blank? && self.patient_id.present?
        patient = Health::Patient.only_deleted.find(self.patient_id) rescue nil
      else
        patient = self.patient
      end
      if patient&.death_date || patient&.epic_patients&.map(&:death_date)&.any? || (rejected && rejected_reason == 'Deceased')
         'Deceased'
      elsif rejected && rejected_reason == 'Declined'
        'Declined Participation'
       elsif rejected && rejected_reason.in?(['Unreachable'])
        'Unreachable/Unable to Contact'
      elsif patient&.engaged?
        'Engaged'
      elsif patient&.qualifying_activities&.exists?
        'In Process'
      else
        'Not Yet Started'
      end
    end

    def inactive_outreach_stati
      [
        'Deceased',
        'Declined Participation',
        'Unreachable/Unable to Contact',
      ]
    end

    def record_status
      # patient has an inactive status, or has been rejected
      if inactive_outreach_stati.include?(outreach_status) || rejected?
        'I'
      else
        'A'
      end
    end

    def disenrolled?
      disenrollment_date.present? || pending_disenrollment_date.present? || removal_acknowledged? || rejected?
    end

    def display_claimed_by_other(agencies)
      cb = display_claimed_by
      other_size = cb.select{|c| c != 'Unknown'}.size
      if other_size > 0
        claimed_by_agencies = (cb & agencies.map(&:name))
        if claimed_by_agencies.any?
          other_size = other_size - claimed_by_agencies.size
        end
        if other_size > 0
          agency = 'Agency'.pluralize(other_size)
          "#{other_size} Other #{agency}"
        end
      else
        'Unknown'
      end
    end

    def display_claimed_by
      claimed = relationships_claimed
      if claimed.any?
        claimed.map{|r| r.agency.name}
      else
        ['Unknown']
      end
    end

    def display_unclaimed_by
      unclaimed = relationships_unclaimed
      unclaimed.map{|r| r.agency.name}
    end

    def convert_to_patient
      # nothing to do if we have a client already
      return if client.present?
      update(effective_date: Date.current)
      # look for an existing patient
      if Health::Patient.where(medicaid_id: medicaid_id).exists?
        patient = Health::Patient.where(medicaid_id: medicaid_id).first
        create_patient(patient.client)
      else
        source_client = create_source_client
        destination_client = connect_destination_client(source_client)
        create_patient(destination_client)
      end
    end

    def create_source_client
      data_source = GrdaWarehouse::DataSource.find_by(short_name: 'Health')
      raise 'Data Source Not Available' if data_source.blank?
      client = GrdaWarehouse::Hud::Client.create(
        data_source_id: data_source.id,
        PersonalID: id,
        FirstName: first_name,
        LastName: last_name,
        SSN: ssn,
        DOB: birthdate,
        DateCreated: Time.now,
        DateUpdated: Time.now
      )
    end

    # we aren't receiving SSN, use full name, case insensitive and birth date
    def matching_destination_client
      if birthdate.present? && first_name.present? && last_name.present?
        GrdaWarehouse::Hud::Client.destination.
          where(
            c_t[:FirstName].lower.eq(first_name.downcase).
            and(c_t[:LastName].lower.eq(last_name.downcase))
          ).
          where(DOB: birthdate).first
      end
    end

    def connect_destination_client source_client
      # attempt to find a match based on exact match of DOB and SSN
      destination_client = matching_destination_client || create_destination_client(source_client)
      GrdaWarehouse::WarehouseClient.create(
        id_in_source: source_client.PersonalID,
        source_id: source_client.id,
        destination_id: destination_client.id,
        data_source_id: source_client.data_source_id
      )
      return destination_client
    end

    def create_destination_client source_client
      destination_data_source_id = GrdaWarehouse::DataSource.destination.pluck(:id).first
      GrdaWarehouse::Hud::Client.create(
        data_source_id: destination_data_source_id,
        PersonalID: source_client.PersonalID,
        FirstName: source_client.FirstName,
        LastName: source_client.LastName,
        SSN: source_client.SSN,
        DOB: source_client.DOB,
        DateCreated: Time.now,
        DateUpdated: Time.now
      )
    end

    def create_patient destination_client
      patient = Health::Patient.where(medicaid_id: medicaid_id).first_or_initialize
      patient.assign_attributes(
        id_in_source: id,
        first_name: first_name,
        last_name: last_name,
        birthdate: birthdate,
        ssn: ssn,
        client_id: destination_client.id,
        medicaid_id: medicaid_id,
        pilot: false,
        engagement_date: engagement_date,
        data_source_id: Health::DataSource.where(name: 'Patient Referral').pluck(:id).first
      )
      patient.save!
      patient.import_epic_team_members
      if rejected?
        # soft delete
        patient.destroy
      end
      update(patient_id: patient.id)
    end

    def self.text_search(text)
      return none unless text.present?
      text.strip!
      pr_t = arel_table
      # Explicitly search for only last, first if there's a comma in the search
      if text.include?(',')
        last, first = text.split(',').map(&:strip)
        where = pr_t[:first_name].lower.matches("#{first.downcase}%")
          .and(pr_t[:last_name].lower.matches("#{last.downcase}%"))
        # Explicity search for "first last"
      elsif text.include?(' ')
        first, last = text.split(' ').map(&:strip)
        where = pr_t[:first_name].lower.matches("#{first.downcase}%")
          .and(pr_t[:last_name].lower.matches("#{last.downcase}%"))
      else
        query = "%#{text.downcase}%"

        where = pr_t[:last_name].lower.matches(query).
          or(pr_t[:first_name].lower.matches(query)).
          or(pr_t[:medicaid_id].lower.matches(query))
      end
      where(where)
    end

  end
end