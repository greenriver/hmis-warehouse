module
  CoreDemographicsReport::HouseholdTypeCalculations
  extend ActiveSupport::Concern
  included do
    def household_type_count(type)
      client_households[type]&.count&.presence || 0
    end

    def household_type_percentage(type)
      total_count = hoh_count
      return 0 if total_count.zero?

      of_type = household_type_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    private def client_households
      @client_households ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          hoh_scope.
            distinct.
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:all] ||= Set.new
              clients[:all] << client_id
            end
          hoh_scope.adult_only_households.
            distinct.
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:without_children] ||= Set.new
              clients[:without_children] << client_id
            end
          hoh_scope.adults_with_children.
            distinct.
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:with_children] ||= Set.new
              clients[:with_children] << client_id
            end
          hoh_scope.child_only_households.
            distinct.
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:only_children] ||= Set.new
              clients[:only_children] << client_id
            end
        end
      end
    end
  end
end
