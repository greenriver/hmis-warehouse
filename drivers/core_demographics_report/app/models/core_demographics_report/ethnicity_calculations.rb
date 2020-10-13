module
  CoreDemographicsReport::EthnicityCalculations
  extend ActiveSupport::Concern
  included do
    def ethnicity_count(type)
      ethnicity_breakdowns[type]&.count&.presence || 0
    end

    def ethnicity_percentage(type)
      total_count = client_ethnicities.count
      return 0 if total_count.zero?

      of_type = ethnicity_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    private def ethnicity_breakdowns
      @ethnicity_breakdowns ||= client_ethnicities.group_by do |_, v|
        v
      end
    end

    private def client_ethnicities
      @client_ethnicities ||= {}.tap do |clients|
        report_scope.joins(:client).order(first_date_in_program: :desc).
          distinct.
          pluck(:client_id, c_t[:Ethnicity], :first_date_in_program).
          each do |client_id, ethnicity, _|
            clients[client_id] ||= ethnicity
          end
      end
    end
  end
end
