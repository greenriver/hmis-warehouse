###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Describes a patient and contains PHI
# Control: PHI attributes NOT documented
module Health::Tracing
  class Case < HealthBase
    acts_as_paranoid
    has_paper_trail

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    has_many :locations
    has_many :contacts
    has_many :site_leaders
    has_many :staffs

    def alert_options
      {
        'Blank' => '',
        'Active' => 'Active',
        'Removed' => 'Removed',
      }
    end

    def yes_no_options
      {
        'No' => '',
        'Yes' => 'Yes',
      }
    end

    def name
      "#{first_name} #{last_name}"
    end

    def matching_contacts(first_name, last_name)
      first_name = first_name.downcase
      last_name = last_name.downcase
      contacts.select do |c|
        c.first_name.downcase.starts_with?(first_name) ||
          c.last_name.downcase.starts_with?(last_name) ||
          c.aliases.downcase.include?(first_name) ||
          c.aliases.downcase.include?(last_name)
      end
    end

    def age date=Date.current
      GrdaWarehouse::Hud::Client.age(date: date.to_date, dob: dob)
    end
  end
end
