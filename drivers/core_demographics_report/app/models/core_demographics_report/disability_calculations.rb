module
  CoreDemographicsReport::DisabilityCalculations
  extend ActiveSupport::Concern
  included do
    def disability_count(type)
      disability_breakdowns[type]&.count&.presence || 0
    end

    def disability_percentage(type)
      total_count = distinct_client_ids.count
      return 0 if total_count.zero?

      of_type = disability_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def no_disability_count
      @no_disability_count ||= distinct_client_ids.count - client_disabilities.count
    end

    def no_disability_percentage
      total_count = distinct_client_ids.count
      return 0 if total_count.zero?

      of_type = no_disability_count
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def yes_disability_count
      @yes_disability_count ||= client_disabilities.count
    end

    def yes_disability_percentage
      total_count = distinct_client_ids.count
      return 0 if total_count.zero?

      of_type = yes_disability_count
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    private def disability_breakdowns
      @disability_breakdowns ||= {}.tap do |disabilities|
        ::HUD.disability_types.keys.each do |d|
          disabilities[d] ||= Set.new
          client_disabilities.each do |id, ds|
            disabilities[d] << id if ds.include?(d)
          end
        end
      end
    end

    private def client_disabilities
      @client_disabilities ||= {}.tap do |clients|
        GrdaWarehouse::Hud::Client.disabled_client_scope.where(id: distinct_client_ids).
          joins(:source_enrollment_disabilities).
          merge(
            GrdaWarehouse::Hud::Disability.
            where(
              DisabilityType: ::HUD.disability_types.keys,
              DisabilityResponse: [1, 2, 3],
              IndefiniteAndImpairs: 1,
            ),
          ).pluck(:id, d_t[:DisabilityType]).each do |client_id, disability|
            clients[client_id] ||= Set.new
            clients[client_id] << disability
          end
      end
    end
  end
end
