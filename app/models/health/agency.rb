module Health
  class Agency < HealthBase
    acts_as_paranoid
    validates_presence_of :name

    has_many :relationships, class_name: 'Health::AgencyPatientReferral', dependent: :destroy
    has_many :assigned_patient_referrals, class_name: 'Health::PatientReferral'
    has_many :agency_users, class_name: 'Health::AgencyUser'

    def users
      User.where(id: (agency_users||[]).map{|au| au.user_id})
    end

    def self.whitelisted_domains
      self.pluck(:acceptable_domains).join(',').split(',').map(&:strip)
    end

    def self.acceptable_domain?(domain)
      whitelisted_domains.include? domain
    end

    def self.email_valid?(email)
      whitelisted_domain_regex.match(email)
    end

    def self.whitelisted_domain_regex
      regex_string = whitelisted_domains.map do |domain|
        ".+#{domain}$"
      end.join('|')
      Regexp.new(regex_string)
    end

  end
end