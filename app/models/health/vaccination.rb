###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class Vaccination < EpicBase
    include RailsDrivers::Extensions
    include ObviousClientMatcher

    MODERNA = 'ModernaTX, Inc.'.freeze
    PFIZER = 'Pfizer, Inc., and BioNTech'.freeze
    JANSSEN = 'Janssen'.freeze

    phi_patient :medicaid_id
    phi_attr :id, Phi::OtherIdentifier
    phi_attr :vaccinated_on, Phi::Date
    phi_attr :vaccinated_at, Phi::SmallPopulation
    phi_attr :vaccination_type, Phi::NeedsReview
    phi_attr :follow_up_cell_phone, Phi::NeedsReview
    phi_attr :client_id, Phi::OtherIdentifier
    phi_attr :epic_patient_id, Phi::OtherIdentifier
    phi_attr :first_name, Phi::Name, 'First name of patient'
    phi_attr :last_name, Phi::Name, 'Last name of patient'
    phi_attr :dob, Phi::Date, 'Date of birth of patient'
    phi_attr :ssn, Phi::Ssn, 'Social security number of patient'
    phi_attr :existed_previously, Phi::NeedsReview

    has_one :patient, primary_key: :medicaid_id, foreign_key: :medicaid_id
    has_one :client, class_name: 'GrdaWarehouse::Hud::Client', primary_key: :client_id, foreign_key: :id
    has_one :he_vaccination, class_name: 'GrdaWarehouse::HealthEmergency::Vaccination', foreign_key: :health_vaccination_id

    scope :unassigned, -> do
      where(client_id: nil)
    end

    scope :assigned, -> do
      where.not(client_id: nil)
    end

    scope :with_phone, -> do
      where.not(follow_up_cell_phone: nil)
    end

    def self.csv_map(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        PAT_ID: :epic_patient_id,
        MEDICAID_ID: :medicaid_id,
        PAT_LAST_NAME: :last_name,
        PAT_FIRST_NAME: :first_name,
        DOB: :dob,
        PHONE: :follow_up_cell_phone,
        SSN: :ssn,
        VACCINATION_DATE: :vaccinated_on,
        VACCINATION_TYPE: :vaccination_type,
        DEPARTMENT_NAME: :vaccinated_at,
        LANG: :preferred_language,
        row_created: :epic_row_created,
        row_updated: :epic_row_updated,
      }
    end

    def self.clean_value(key, value)
      value = case key
      when :ssn
        if value == '999-99-9999'
          nil
        else
          value
        end
      when :follow_up_cell_phone
        if value == 'NONE'
          nil
        else
          value
        end
      when :dob, :vaccinated_on
        value = value.tr('/', '-')&.split(' ')&.first
        if /\d{1,2}-\d{1,2}-\d{4}/.match?(value)
          month, day, year = value.split('-')
          value = Date.new(year.to_i, month.to_i, day.to_i)
        end

        value
      else
        if value == 'NULL'
          nil
        else
          value.presence
        end
      end
      super(key, value)
    end

    # Called from ImportEpic
    def self.process_new_data(values)
      # Ensure we only have one per conflict key or SQL will be very unhappy
      values = values.index_by { |m| m.slice(*conflict_key) }.values
      # Remove any that were removed from the source
      remove_missing!(values)

      # Import new
      import(
        values,
        on_duplicate_key_update: {
          conflict_target: conflict_key,
          columns: [:first_name, :last_name, :ssn, :dob, :vaccinated_at, :vaccination_type, :follow_up_cell_phone],
        },
      )
      propagate_to_clients

      queue_sms if RailsDrivers.loaded.include?(:text_message)
    end

    def self.conflict_key
      [:epic_patient_id, :vaccinated_on]
    end

    def self.remove_missing!(values)
      existing_keys = pluck(*conflict_key)
      return unless existing_keys.present?

      incoming_keys = values.map { |m| m.slice(*conflict_key).values }.map { |m_id, date| [m_id, date.to_date] }
      to_remove = existing_keys - incoming_keys
      to_remove.each do |epic_patient_id, vaccinated_on|
        where(epic_patient_id: epic_patient_id, vaccinated_on: vaccinated_on.to_date).destroy_all
      end
    end

    def self.propagate_to_clients
      # Update existing Health Emergency vaccinations if they've changed
      assigned.preload(:he_vaccination).find_each do |vaccination|
        vaccination.he_vaccination.vaccinated_on = vaccination.vaccinated_on
        vaccination.he_vaccination.vaccination_type = vaccination.clean_vaccination_type
        vaccination.he_vaccination.vaccinated_at = vaccination.vaccinated_at
        vaccination.he_vaccination.follow_up_cell_phone = vaccination.follow_up_cell_phone
        vaccination.he_vaccination.save if vaccination.he_vaccination.changed?
      end
      # Remove any imported Health Emergency vaccinations where we've deleted the imported one
      GrdaWarehouse::HealthEmergency::Vaccination.imported.
        where.not(health_vaccination_id: assigned.pluck(:id)).
        destroy_all

      # Add new vaccinations
      system_user_id = User.setup_system_user.id
      new_vaccinations = []
      # a list of destination clients gets cached in #clients per instance
      # setup a temporary instance to hold the cache
      lookup_cache = new
      unassigned.preload(:patient).find_each do |vaccination|
        # Attempt to find the client based on medicaid_id
        client_id = if vaccination.patient&.client_id.present?
          vaccination.patient.client_id
        else
          all_matches = lookup_cache.matching_clients(
            ssn: vaccination.ssn,
            dob: vaccination.dob,
            first_name: vaccination.first_name,
            last_name: vaccination.last_name,
          )

          obvious_matches = all_matches.uniq.map { |i| i if all_matches.count(i) > 1 }.compact
          # Return first matching client_id
          if obvious_matches.any?
            obvious_matches.first[:id]
          else # rubocop:disable Style/EmptyElse
            nil
          end
        end
        if client_id.present?
          he_vaccination = GrdaWarehouse::HealthEmergency::Vaccination.new(
            client_id: client_id,
            health_vaccination_id: vaccination.id,
            emergency_type: GrdaWarehouse::Config.get(:health_emergency),
            user_id: system_user_id,
            vaccinated_on: vaccination.vaccinated_on,
            vaccination_type: vaccination.clean_vaccination_type,
            vaccinated_at: vaccination.vaccinated_at,
            follow_up_cell_phone: vaccination.follow_up_cell_phone,
          )
          he_vaccination.follow_up_on = he_vaccination.follow_up_date
          new_vaccinations << he_vaccination
          vaccination.update(client_id: client_id)
        end
      end
      GrdaWarehouse::HealthEmergency::Vaccination.import(new_vaccinations) if new_vaccinations.present?
    end

    def self.vaccination_type_options
      {
        'ModernaTX, Inc.' => MODERNA,
        'Pfizer, Inc., and BioNTech' => PFIZER,
        'Janssen COVID-19 Vaccine' => JANSSEN,
      }
    end

    def clean_vaccination_type
      {
        'Moderna' => MODERNA,
        'Pfizer' => PFIZER,
        'Janssen' => JANSSEN,
      }[vaccination_type]
    end

    # NOTE: called on initialized vaccination in the controller
    # to determine follow_up_date
    def follow_up_date
      return unless vaccinated_on

      case clean_vaccination_type
      when MODERNA
        vaccinated_on + 28.days if similar_vaccinations.count.zero?
      when PFIZER
        vaccinated_on + 21.days if similar_vaccinations.count.zero?
      when JANSSEN
        return # no follow-up needed
      end
    end

    private def similar_vaccinations
      self.class.where(epic_patient_id: epic_patient_id, vaccination_type: vaccination_type).
        where.not(id: id)
    end
  end
end
