###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class Vaccination < GrdaWarehouseBase
    include ::HealthEmergency

    MODERNA = 'ModernaTX, Inc.'.freeze
    PFIZER = 'Pfizer, Inc., and BioNTech'.freeze

    validates_presence_of :vaccinated_on, :vaccination_type, on: :create
    scope :visible_to, ->(user) do
      return current_scope if user.can_see_health_emergency_clinical?

      none
    end

    scope :active, -> do
      where(restricted: 'Yes')
    end

    scope :added_within_range, ->(range=DateTime.current..DateTime.current) do
      # FIXME: unclear why, but because we get dates and compare to times, postgres gets very unhappy
      end_date = range.last + 2.days
      range = Time.zone.at(range.first.to_time)..Time.zone.at(end_date.to_time)
      where(created_at: range)
    end

    scope :unsent, -> do
      where(follow_up_notification_sent_at: nil)
    end

    scope :imported, -> do
      where.not(health_vaccination_id: nil)
    end

    def visible_to?(user)
      user.can_see_health_emergency_medical_restriction?
    end

    def sort_date
      updated_at
    end

    def title
      'Vaccination'
    end

    def pill_title
      'Vaccination'
    end

    def status
      case vaccination_type
      when MODERNA, PFIZER
        case similar_vaccinations.count
        when 1
          if follow_up_on.present?
            "Follow-up dose needed #{follow_up_on}"
          else
            "Initial Dose given #{vaccinated_on}"
          end
        else
          'Vaccinated'
        end
      else
        'Vaccinated'
      end
    end

    private def similar_vaccinations
      client.health_emergency_vaccinations.where(vaccination_type: vaccination_type)
    end

    def vaccination_type_options
      {
        'ModernaTX, Inc.' => MODERNA,
        'Pfizer, Inc., and BioNTech' => PFIZER,
      }
    end

    def location_options
      self.class.distinct.
        where.not(vaccinated_at: [nil, '']).
        order(:vaccinated_at).
        pluck(:vaccinated_at)
    end

    # NOTE: called on initialized vaccination in the controller
    # to determine follow_up_date
    def follow_up_date
      case vaccination_type
      when MODERNA, PFIZER
        vaccinated_on + 21.days if similar_vaccinations.count.zero?
      end
    end
  end
end
