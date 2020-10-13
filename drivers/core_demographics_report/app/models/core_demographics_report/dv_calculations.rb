module
  CoreDemographicsReport::DvCalculations
  extend ActiveSupport::Concern
  included do
    def dv_count(type)
      dv_breakdowns[type]&.count&.presence || 0
    end

    def dv_percentage(type)
      total_count = client_dv_occurancess.count
      return 0 if total_count.zero?

      of_type = dv_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    private def dv_breakdowns
      @dv_breakdowns ||= client_dv_occurancess.group_by do |_, v|
        v
      end
    end

    private def client_dv_occurancess
      @client_dv_occurancess ||= {}.tap do |clients|
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
  end
end
