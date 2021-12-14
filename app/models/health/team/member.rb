###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class Team::Member < HealthBase
    include ArelHelper
    self.table_name = 'team_members'
    has_paper_trail versions: { class_name: 'Health::HealthVersion' }
    acts_as_paranoid

    phi_patient :patient_id
    phi_attr :id, Phi::OtherIdentifier, 'ID of team member'
    phi_attr :user_id, Phi::SmallPopulation, 'ID of user'
    phi_attr :last_contact, Phi::Date, 'Date of last contact'

    # belongs_to :team, class_name: 'Health::Team', optional: true
    belongs_to :patient, optional: true

    validates :email, email_format: { check_mx: true }, length: { maximum: 250 }, allow_blank: true
    validate :email_domain_if_present
    validates_presence_of :first_name, :last_name, :organization

    scope :with_email, -> do
      where.not(email: [nil, ''])
    end

    # Disabled in favor of using some gems to blacklist some domains.  This might come back
    # scope :health_sendable, -> do
    #   domain_query = Health::Agency.whitelisted_domains.map do |domain|
    #     nf('LOWER', [arel_table[:email]]).matches("%#{domain}")
    #   end.reduce(&:or)
    #   with_email.where(domain_query)
    # end

    def self.member_type_name
      raise 'Implement in sub-class'
    end

    def member_type_name
      self.class.member_type_name
    end

    def self.class_from_member_type_name name
      return Health::Team::Provider if name == 'General'

      names = Hash[available_types.map(&:member_type_name).zip(available_types)]
      names[name] || Health::Team::Other
    end

    def self.available_types
      [
        Health::Team::Provider,
        Health::Team::PcpDesignee,
        Health::Team::CaseManager,
        Health::Team::Nurse,
        Health::Team::AcoCareManager,
        Health::Team::Behavioral,
        Health::Team::Representative,
        Health::Team::Other,
        Health::Team::CareCoordinator,
      ]
    end

    def self.icon_for(member_type_name)
      {
        'Behavioral Health' => ' icon-mental-health',
        'SDH Case Manager' => 'icon-helping-hands',
        'Nurse Care Manager' => 'icon-nurse-clipboard',
        'Other Important Contact' => 'icon-reminder',
        'Provider (MD/NP/PA)' => 'icon-medical-provider',
        'Designated Representative' => 'icon-users',
        'ACO Care Manager' => 'icon-nurse-clipboard',
        'PCP Designee' => 'icon-medical-provider',
        'Care Coordinator' => 'icon-helping-hands',
      }[member_type_name]
    end

    def self.icon
      icon_for(member_type_name)
    end

    def full_name
      ["#{first_name} #{last_name}", title.presence].compact.join(', ')
    end

    def careplans
      Health::Careplan.
        where('responsible_team_member_id = ? OR provider_id = ? OR representative_id = ?', id, id, id)
    end

    def remove_from_careplans
      Health::Careplan.where(responsible_team_member_id: id).each do |cp|
        cp.update(responsible_team_member_id: nil)
      end
      Health::Careplan.where(provider_id: id).each do |cp|
        cp.update(provider_id: nil)
      end
      Health::Careplan.where(representative_id: id).each do |cp|
        cp.update(representative_id: nil)
      end
    end

    def remove_from_goals
      Health::Goal::Base.where(responsible_team_member_id: id).each do |goal|
        goal.update(responsible_team_member_id: nil)
      end
    end

    def goals
      Health::Goal::Base.where(responsible_team_member_id: id)
    end

    def in_use?
      careplans.any? || goals.any?
    end

    def email_domain_if_present
      return if email.blank?

      errors.add(:email, 'address must match a provider organization domain (e.g. @tuftsmedical.org — can\'t be @gmail.com or other generic domain)') unless Health::Agency.email_valid?(email)
    end

    def self.as_health_contacts(_force = false)
      contact_columns = {
        patient_id: :patient_id,
        source_id: :id,
        source_type: :type,
        description: :title,
        phone: :phone,
        email: :email,
        collected_on: :date_of_last_contact,
      }.invert

      Health::Team::Member.all.map do |row|
        contact = row.slice(*contact_columns.keys)
        contact.transform_keys! { |k| contact_columns[k.to_sym] }
        contact.merge(
          name: row.full_name,
          category: row.type.split('::').last,
        )
      end
    end
  end
end
