###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Stateless, QA data lives in associated model
module Health
  class QualifyingActivityBase
    def modes_of_contact
      @modes_of_contact ||= self.class.modes_of_contact
    end

    def client_reached
      @client_reached ||= self.class.client_reached
    end

    def activities
      @activities ||= self.class.activities
    end

    def self.css_class
      name.parameterize(separator: '_')
    end

    def self.js_model
      @js_model ||= "{range_start: new Date(\'#{self::EFFECTIVE_DATE_RANGE.begin&.strftime('%Y-%m-%dT00:00:00') || '2000-01-01T00:00:00'}\'),
        range_end: new Date(\'#{self::EFFECTIVE_DATE_RANGE.end&.strftime('%Y-%m-%dT23:59:59') || '2099-12-31T00:00:00'}\'),
        css_class: \"#{css_class}\",
      }"
    end

    def self.mode_of_contact_collection
      modes_of_contact.
        map { |k, mode| [mode[:title], k] }
    end

    def self.reached_client_collection
      client_reached.
        map { |k, mode| [mode[:title], k] }
    end

    def self.activity_collection
      activities.
        reject { |_k, mode| mode[:hidden] }.
        map { |k, mode| [mode[:title], k] }
    end

    def modifiers(qa)
      # Attach modifiers from activity
      modlist = activities[qa.activity&.to_sym].try(:[], :code)&.split(/[ |>]/).try(:[], 1..)

      # Attach modifiers from contact, if present
      modlist << modes_of_contact[qa.mode_of_contact&.to_sym].try(:[], :code)
      modlist << client_reached[qa.reached_client&.to_sym].try(:[], :code)

      return modlist.reject(&:blank?).compact
    end
  end
end
