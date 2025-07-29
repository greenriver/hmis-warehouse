
module Hmis::Ce::Match
  class MatchableClientsQuery
    def self.call(...) = new.call(...)

    def call
      scope :destinations_with_active_enrollments, ->(range=nil) do
        now = Time.current
        range ||= 90.days.ago.to_date..Date.current
        enrollments = GrdaWarehouse::Hud::Enrollment.open_during_range(range)

        GrdaWarehouse::Hud::Client.destination
          .joins(hmis_source_clients: :enrollments)
          .merge(enrollments)
          .distinct
      end
    end

    protected

    def matchable_enrollments
      scope = GrdaWarehouse::Hud::Enrollment
      cutoff = enrollment_cutoff_days

      # if no cutoff configured, use all enrollments
      return scope unless cutoff

      now = Date.current
      range = (now -

      range ? scope.open_during_range(range) : scope
    end

    def enrollment_range
      range ||= 90.days.ago.to_date..Date.current
    end

    def enrollment_cutoff_days
      key = 'enrollment_cutoff'
      value = AppConfigProperty.where(key: "hmis_ce/#{key}").first.presence
      return nil unless value

      DateTime.parse(value)
    end
  end
end
