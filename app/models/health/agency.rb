###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: None - contains no PHI
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

    # def self.whitelisted_domains
    #   self.pluck(:acceptable_domains).join(',').split(',').map(&:strip).select(&:present?)
    # end

    # def self.acceptable_domain?(domain)
    #   whitelisted_domains.include? domain
    # end

    def self.email_valid?(email)
      return false unless email.present?
      # whitelisted_domain_regex.match(email)
      # Check that the email is not from a free or disposable or invalid email provider
      email_address = ::EmailCheck::EmailAddress.new(email)
      return false if email_address.blank?
      ! email_address.free_email_provider? && ! email_address.blacklisted_domain? && MailChecker.valid?(email)
    end

    def self.whitelisted_domain_regex
      regex_string = whitelisted_domains.map do |domain|
        ".+#{domain}$"
      end.join('|')
      Regexp.new(regex_string)
    end

  end
end
