module
  CoreDemographicsReport::DvCalculations
  extend ActiveSupport::Concern
  included do
    def dv_occurrence_count(type)
      dv_occurrence_breakdowns[type]&.count&.presence || 0
    end

    def dv_occurrence_percentage(type)
      total_count = client_dv_occurrences.count
      return 0 if total_count.zero?

      of_type = dv_occurrence_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    private def dv_occurrence_breakdowns
      @dv_occurrence_breakdowns ||= client_dv_occurrences.group_by do |_, v|
        v
      end
    end

    private def client_dv_occurrences
      @client_dv_occurrences ||= {}.tap do |clients|
        report_scope.joins(enrollment: :health_and_dvs).order(hdv_t[:InformationDate].desc).
          merge(
            GrdaWarehouse::Hud::HealthAndDv.where(
              InformationDate: @filter.range,
              DomesticViolenceVictim: 1,
            ),
          ).
          distinct.
          pluck(:client_id, hdv_t[:WhenOccurred], hdv_t[:InformationDate]).
          each do |client_id, when_occurred, _|
            clients[client_id] ||= when_occurred
          end
      end
    end

    def dv_status_count(type)
      dv_status_breakdowns[type]&.count&.presence || 0
    end

    def dv_status_percentage(type)
      total_count = client_dv_stati.count
      return 0 if total_count.zero?

      of_type = dv_status_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    private def dv_status_breakdowns
      @dv_status_breakdowns ||= client_dv_stati.group_by do |_, v|
        v
      end
    end

    private def client_dv_stati
      @client_dv_stati ||= {}.tap do |clients|
        report_scope.joins(enrollment: :health_and_dvs).order(hdv_t[:InformationDate].desc).
          merge(GrdaWarehouse::Hud::HealthAndDv.where(InformationDate: @filter.range)).
          distinct.
          pluck(:client_id, hdv_t[:DomesticViolenceVictim], hdv_t[:InformationDate]).
          each do |client_id, status, _|
            clients[client_id] ||= status
          end
      end
    end
  end
end
