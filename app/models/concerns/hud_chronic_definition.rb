module HudChronicDefinition
  extend ActiveSupport::Concern

  # added as instance methods
  included do
    has_many :hud_chronics, class_name: GrdaWarehouse::HudChronic.name, inverse_of: :client

    # HUD Chronic:
    # Client must be disabled
    # Must be homeless for all of the last 12 months
    #   OR
    # Must be homeless 12 of the last 36 with 4 episodes
    def hud_chronic? on_date: Date.today
      if hoh_disabled?(on_date: on_date)
        if months_12_homeless?(on_date: on_date)
          true
        elsif times_4_homeless?(on_date: on_date)
          if months_homeless_past_three_years_more_than_12?(on_date: on_date)
            true
          elsif total_months_homeless_more_than_12?(on_date: on_date)
            true
          end
        end
      end
    end
      

    def total_months_homeless_more_than_12? on_date:
      entry = service_history.hud_homeless.
        entry.ongoing(date: on_date).first
        order(first_date_in_program: :desc).first
      months_on_street = entry&.enrollment&.
        MonthsHomelessPastThreeYears
      return false unless months_on_street
      return false unless months_on_street > 100
      months_in_project = (on_date.year * 12 + on_date.month) - (entry.first_date_in_program.year * 12 + entry.first_date_in_program.month) + 1
      (months_on_street - 100) + months_in_project >= 12
    end

    def months_homeless_past_three_years_more_than_12? on_date:
      months_on_street = service_history.hud_homeless.
        entry.ongoing(date: on_date).
        order(first_date_in_program: :desc).first&.enrollment&.
        MonthsHomelessPastThreeYears
      return false unlesss months_on_street
      # 8, 9, 99 are missing, reused etc.
      months_on_street > 111
    end
    def times_4_homeless? on_date:
      times_on_street = service_history.hud_homeless.
        entry.ongoing(date: on_date).
        order(first_date_in_program: :desc).first&.enrollment&.TimesHomelessPastThreeYears
      times_on_street == 4
    end

    def months_12_homeless? on_date:
      date_to_street = service_history.hud_homeless.
        entry.ongoing(date: on_date).
        order(first_date_in_program: :desc).first&.enrollment&.DateToStreetESSH
      return false unless date_to_street
      # how many unique months between data_to_street and on_date
      months_on_street = (on_date.year * 12 + on_date.month) - (date_to_street.year * 12 + date_to_street.month) + 1 # plus one for current month 
      months_on_street >= 12
    end
    def hoh_disabled? on_date:
      entry = service_history.hud_homeless.
        entry.ongoing(date: on_date).
        order(first_date_in_program: :desc).first
      entry&.head_of_household.source_enrollments.pluck(:DisablingCondition).include?(1)
    end

    def hoh_residing? in_places:, on_date:, days: nil
      if days
        date_to_street = service_history.hud_homeless.
          entry.ongoing(date: on_date).
          order(first_date_in_program: :desc).first&.enrollment&.DateToStreetESSH
        return false unless date_to_street
        (on_date - date_to_street).to_i >= days
      else
        service_history.hud_homeless.
          entry.ongoing(date: on_date).exists?
      end
    end

  end

  # added as class methods
  class_methods do
  end

end