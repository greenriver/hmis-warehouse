module HudChronic
  extend ActiveSupport::Concern

  # added as instance methods
  included do
    has_many :hud_chronics, class_name: GrdaWarehouse::HudChronic.name, inverse_of: :client

    def hud_chronic? date: Date.today
      if head_of_household_disabled?(on: date)
        if head_of_household_residing?(in: [:shelter, :street, :haven])
          if head_of_household_residing?(for: 12.months)
            true
          elsif head_of_household_residing?(in: [:shelter, :street, :haven], for: 12.months, over: 3.years)
          end
        end
      else
        false
      end
    end

    def head_of_household_disabled? on: nil
      entry = service_history.entry.where("first_date_in_program <= ? AND last_date_in_program >= ?", on, on).first
      entry&.head_of_household&.disabling_condition?
    end

  end

  # added as class methods
  class_methods do
  end

end