module Health
  class PatientReferral < HealthBase
    include PatientReferralImporter
    include ArelHelper
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
      Deceased: 7,
    }

    scope :assigned, -> {where(rejected: false).where.not(agency_id: nil)}
    scope :unassigned, -> {where(rejected: false).where(agency_id: nil)}
    scope :rejected, -> {where(rejected: true)}

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
    belongs_to :patient, required: false
    belongs_to :aco, class_name: 'Health::AccountableCareOrganization', foreign_key: :accountable_care_organization_id

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
      relationships.where(agency_id: agency).last
    end

    def assigned?
      agency_id.present?
    end

    def engagement_date
      return nil unless effective_date.present?
      next_month = effective_date.at_beginning_of_month.next_month
      if effective_date < '2018-09-01'.to_date
        (next_month + 120.days).to_date
      else
        (next_month + 90.days).to_date
      end
    end

    def name
      "#{first_name} #{last_name}"
    end

    def age
      if birthdate.present?
        GrdaWarehouse::Hud::Client.age(dob: birthdate.to_date, date: Date.today)
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
      if patient&.death_date || patient&.epic_patients&.map(&:death_date)&.any? || (rejected && rejected_reason == 'Deceased')
         'Deceased'
      elsif patient&.engaged?
        'Engaged'
      elsif rejected && rejected_reason == 'Declined'
        'Declined Participation'
      elsif rejected && rejected_reason.in?(['Unreachable'])
        'Unreachable/Unable to Contact'
      elsif patient.present?
        'In Process'
      else
        'Not Yet Started'
      end
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
      update(effective_date: Date.today)
      source_client = create_source_client
      destination_client = connect_destination_client(source_client)
      create_patient(destination_client)
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
      patient = Health::Patient.create(
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