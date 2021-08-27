###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class PatientReferral < HealthBase
    include PatientReferralImporter
    include ArelHelper

    REENROLLMENT_REQUIRED_AFTER_DAYS = 90

    acts_as_paranoid

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
    phi_attr :identification, Phi::LicenceNumber # Phi::NeedsReview ??
    # phi_attr :record_status
    phi_attr :record_updated_on, Phi::Date
    phi_attr :exported_on, Phi::Date
    # phi_attr :removal_acknowledge
    phi_attr :disenrollment_date, Phi::Date
    phi_attr :pending_disenrollment_date, Phi::Date, <<~DESC
      A disenrollment date received via ANSI 834. Once acknowledged it is copied
      to disenrollment_date. However for the purposes of payments it can be
      considered to be the effective disenrollment date.
    DESC
    phi_attr :stop_reason_description, Phi::FreeText, <<~DESC
      A description of why the enrollment was cancelled.
    DESC

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

    scope :prior, -> { where(current: false) }

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
    scope :not_disenrolled, -> { current.where(pending_disenrollment_date: nil, disenrollment_date: nil) }

    # Note: respects pending_disenrollment_date if there is no disenrollment_date
    scope :active_within_range, ->(start_date:, end_date:) do
      at = arel_table
      # Excellent discussion of why this works:
      # http://stackoverflow.com/questions/325933/determine-whether-two-date-ranges-overlap
      d_1_start = start_date
      d_1_end = end_date
      d_2_start = at[:enrollment_start_date]
      d_2_end = cl(at[:disenrollment_date], at[:pending_disenrollment_date])
      # Currently does not count as an overlap if one starts on the end of the other
      where(d_2_end.gteq(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lteq(d_1_end)))
    end

    scope :referred_on, ->(date) do
      where(enrollment_start_date: date)
    end

    scope :at_acos, ->(aco_ids) do
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

    def self.first_enrollment_start_date
      Rails.cache.fetch('first_health_enrollment_start_date', expires_in: 1.hours) do
        # We never want to calculate this back before 2017, so ignore any bad enrollment start dates before that
        [Health::PatientReferral.minimum(:enrollment_start_date), '2017-01-01'.to_date].compact.max
      end
    end

    def self.create_referral(patient, args)
      referral_args = args.merge(current: true, contributing: true)
      if patient.present?
        # Re-enrollment
        referral_args.merge!(patient: patient)
        current_referral = patient.patient_referral
        patient.patient_referrals.contributing.update_all(current: false)

        enrollment_start_date = referral_args[:enrollment_start_date]
        last_disenrollment_date = current_referral.actual_or_pending_disenrollment_date
        if last_disenrollment_date.nil?
          # Last referral was not disenrolled. For record keeping, close the last enrollment, and immediately open a new one
          current_referral.update(
            disenrollment_date: enrollment_start_date,
            change_description: 'Close open enrollment',
            removal_acknowledged: true, # Synthetic removals do not need to be acknowledged
          )
          referral = create(referral_args)
        elsif (enrollment_start_date - last_disenrollment_date.next_day).to_i > REENROLLMENT_REQUIRED_AFTER_DAYS
          # It has been more than REENROLLMENT_REQUIRED_AFTER_DAYS days, so this is a "reenrollment", so close the contributing range
          patient.patient_referrals.contributing.update_all(contributing: false)
          referral = create(referral_args)
          patient.reenroll!(referral)
        else
          # This is an "auto-reenrollment"
          # current was set to false above, remains contributing...
          referral = create(referral_args)
        end
      else
        referral = create(referral_args)
        referral.convert_to_patient
      end

      referral.patient.update(engagement_date: referral.engagement_date) unless referral.keep_engagement_date?

      referral
    end

    def should_clear_assignment?
      enrollment_start_date_changed?
    end

    def client
      patient&.client
    end

    accepts_nested_attributes_for :relationships

    def update_rejected_from_reason
      if rejected_reason_none?
        self.rejected = false
      else
        self.rejected = true
      end
      return true
    end

    def relationship_to(agency)
      relationships.select { |r| r.agency_id == agency.id }&.last
    end

    def assigned?
      agency_id.present?
    end

    def keep_engagement_date?
      patient.care_plan_signed? && Date.current <= patient.engagement_date
    end

    ENGAGEMENT_IN_DAYS = 150
    # The engagement date is the date by which a patient must be engaged
    def engagement_date
      return nil unless enrollment_start_date.present?

      # Historical calculations...
      # Before 2018-09-01, engagement was 120 days following the start of the month following enrollment
      # Until 2020-04-01, engagement was 90 days following the start of the month following enrollment

      (enrollment_start_date + ENGAGEMENT_IN_DAYS).to_date
    end

    def enrolled_days_to_date
      (enrollment_start_date .. (actual_or_pending_disenrollment_date || Date.current)).to_a
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
      if patient.blank? && patient_id.present?
        patient = begin
                    Health::Patient.only_deleted.find(patient_id)
                  rescue StandardError
                    nil
                  end
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

    # In many cases it is handy to consider a pending_disenrollment
    # if no disenrollment has been yet been recorded
    def actual_or_pending_disenrollment_date
      disenrollment_date || pending_disenrollment_date
    end

    private def was_active_range
      return nil unless enrollment_start_date

      # disenrollment_date date might be nil but Range handles that for us
      (enrollment_start_date ..actual_or_pending_disenrollment_date)
    end

    # Note: respects pending_disenrollment_date if there is no disenrollment_date
    def active_within?(range)
      was_active_range&.overlaps?(range)
    end

    # Note: respects pending_disenrollment_date if there is no disenrollment_date
    def active_on?(date)
      was_active_range&.cover?(date)
    end

    def re_enrollment_blackout?(on_date)
      removal_acknowledged? && on_date < disenrollment_date + 30.days
    end

    def display_claimed_by_other(agencies)
      cb = display_claimed_by
      other_size = cb.reject { |c| c == 'Unknown' }.size
      if other_size.positive?
        claimed_by_agencies = (cb & agencies.map(&:name))
        other_size -= claimed_by_agencies.size if claimed_by_agencies.any?
        if other_size.positive?
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
        claimed.map { |r| r.agency.name }
      else
        ['Unknown']
      end
    end

    def display_unclaimed_by
      unclaimed = relationships_unclaimed
      unclaimed.map { |r| r.agency.name }
    end

    def convert_to_patient
      # nothing to do if we have a client already
      return true if client.present?

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

      GrdaWarehouse::Hud::Client.create(
        data_source_id: data_source.id,
        PersonalID: id,
        FirstName: first_name,
        LastName: last_name,
        SSN: ssn,
        DOB: birthdate,
        DateCreated: Time.now,
        DateUpdated: Time.now,
      )
    end

    # we aren't receiving SSN, use full name, case insensitive and birth date
    def matching_destination_client
      return unless birthdate.present? && first_name.present? && last_name.present?

      GrdaWarehouse::Hud::Client.destination.
        where(
          c_t[:FirstName].lower.eq(first_name.downcase).
          and(c_t[:LastName].lower.eq(last_name.downcase)),
        ).
        where(DOB: birthdate).first
    end

    def connect_destination_client source_client
      # attempt to find a match based on exact match of DOB and SSN
      destination_client = matching_destination_client || create_destination_client(source_client)
      GrdaWarehouse::WarehouseClient.create(
        id_in_source: source_client.PersonalID,
        source_id: source_client.id,
        destination_id: destination_client.id,
        data_source_id: source_client.data_source_id,
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
        DateUpdated: Time.now,
      )
    end

    def create_patient destination_client
      linked_patient = Health::Patient.with_deleted.find_by(client_id: destination_client.id)
      patient = Health::Patient.with_deleted.where(medicaid_id: medicaid_id).first_or_initialize

      # The medicaid id has changed, or points to a different client!
      raise MedicaidIdConflict, "Patient: #{patient.client_id}, linked_patient: #{linked_patient.id}" if linked_patient.present? && patient.client_id != linked_patient.id

      patient.assign_attributes(
        id_in_source: id,
        first_name: first_name,
        last_name: last_name,
        birthdate: birthdate,
        ssn: ssn,
        client_id: destination_client.id,
        medicaid_id: medicaid_id,
        pilot: false,
        # engagement_date: engagement_date,
        data_source_id: Health::DataSource.where(name: 'Patient Referral').pluck(:id).first,
        deleted_at: nil,
      )
      patient.save!
      patient.import_epic_team_members
      update(patient_id: patient.id)
    end

    def self.text_search(text)
      return none unless text.present?

      text.strip!
      pr_t = arel_table
      # Explicitly search for only last, first if there's a comma in the search
      if text.include?(',')
        last, first = text.split(',').map(&:strip)
        where = pr_t[:first_name].lower.matches("#{first.downcase}%").
          and(pr_t[:last_name].lower.matches("#{last.downcase}%"))
        # Explicity search for "first last"
      elsif text.include?(' ')
        first, last = text.split(' ').map(&:strip)
        where = pr_t[:first_name].lower.matches("#{first.downcase}%").
          and(pr_t[:last_name].lower.matches("#{last.downcase}%"))
      else
        query = "%#{text.downcase}%"

        where = pr_t[:last_name].lower.matches(query).
          or(pr_t[:first_name].lower.matches(query)).
          or(pr_t[:medicaid_id].lower.matches(query))
      end
      where(where)
    end

    def compute_enrollment_changes
      current = self
      previous = current.paper_trail.previous_version
      last_event = nil
      disenrollments = []

      while previous.present?
        if current.disenrollment_date.present? && previous.disenrollment_date.blank?
          last_event = :disenrollment
          disenrollments << current.dup
        elsif current.pending_disenrollment_date.present? && previous.pending_disenrollment_date.blank? && current.disenrollment_date.blank?
          # found a pending disenrollment
          unless last_event == :disenrollment
            # Unless we already saw a disenrollment that confirmed this...
            disenrollments << current.dup
            last_event = :pending_disenrollment
          end
        end

        current = previous
        previous = current.paper_trail.previous_version
      end

      disenrollments
    end

    def build_derived_referrals
      disenrollments = compute_enrollment_changes
      return [] unless disenrollments.present?
      return [] if disenrollments.size == 1 && disenrolled?

      disenrollments.reverse.each_with_index.map do |older_referral, index|
        newer_referral = disenrollments[index + 1] || self
        enrolled_on = newer_referral.enrollment_start_date
        disenrolled_on = older_referral.disenrollment_date || older_referral.pending_disenrollment_date
        within_required_days = (enrolled_on - disenrolled_on).to_i <= REENROLLMENT_REQUIRED_AFTER_DAYS
        older_referral.assign_attributes(current: false, contributing: within_required_days, derived_referral: true)

        older_referral
      end

      disenrollments
    end

    def disenrolled?
      actual_or_pending_disenrollment_date.present?
    end

    def self.encounter_report_details
      {
        source: 'Warehouse',
      }
    end

    def self.cleanup_referrals
      referral_source = joins(:patient) # Limit to referrals with patients
      cleanup_time = Date.today.to_time

      # Any non-current enrollments should have a disenrollment date
      # Assign the day before the current enrollment start date, if one exists, otherwise leave it, as something else is
      # wrong...
      hanging_enrollments = referral_source.where(current: false, pending_disenrollment_date: nil, disenrollment_date: nil)
      hanging_enrollments.each do |referral|
        disenrollment_date = referral.patient.patient_referral&.enrollment_start_date&.prev_day
        # If the current enrollment is on our start date, then make it an empty enrollment, which will be cleaned up later...
        disenrollment_date = referral.enrollment_start_date if disenrollment_date.present? && disenrollment_date < referral.enrollment_start_date
        referral.update(disenrollment_date: disenrollment_date)
      end

      # An empty referral is one where the enrollment and disenrollment date are the same.
      empty_referrals = referral_source.where(current: false).
        where(
          hpr_t[:enrollment_start_date].eq(hpr_t[:disenrollment_date]).
            or(hpr_t[:enrollment_start_date].eq(hpr_t[:pending_disenrollment_date]).
              and(hpr_t[:disenrollment_date].eq(nil))),
        )
      # Remove the empty referrals
      empty_referrals.update_all(deleted_at: cleanup_time)

      # Multiple referrals for a patient that start on the same day
      referral_groups = referral_source.group(:patient_id, hpr_t[:enrollment_start_date]).count
      referral_groups_with_duplicate_starts = referral_groups.select { |_key, v| v > 1 }

      # Go through each (patient, start date) pair
      referral_groups_with_duplicate_starts.keys.each do |patient_id, enrollment_start_date|
        referrals = referral_source.where(patient_id: patient_id, enrollment_start_date: enrollment_start_date)
        older_referrals = referrals.where(current: false) # The older referrals are not current
        if referrals.count == older_referrals.count
          # All the referrals are older, so, just keep the longest one
          longest_referral = nil
          longest_referral_length = nil
          older_referrals.each do |referral|
            referral_start = referral.enrollment_start_date
            referral_end = referral.disenrollment_date || referral.pending_disenrollment_date # older referrals must have an end
            days = (referral_end - referral_start).to_i
            if longest_referral_length.nil? || days > longest_referral_length
              longest_referral = referral
              longest_referral_length = days
            end
          end
          # Remove all but the longest, and make sure we have a current referral
          referrals.where.not(id: longest_referral.id).update_all(deleted_at: cleanup_time)
          longest_referral.update(current: true) if longest_referral.patient.patient_referral.blank?
        else
          # There is a current referral in the duplicates, remove the older referrals, leaving the current one
          older_referrals.update_all(deleted_at: cleanup_time)
        end
      end
    end
  end

  class MedicaidIdConflict < StandardError; end
end
