###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HapReport::Queries
  extend ActiveSupport::Concern
  include  ArelHelper

  included do
    def a_t
      HapReport::HapClient.arel_table
    end

    # Project types
    def bridge_housing
      lit('2').eq(any(a_t[:project_types]))
    end

    def case_management
      lit('6').eq(any(a_t[:project_types]))
    end

    def rental_assistance
      lit('12').eq(any(a_t[:project_types]))
    end

    def emergency_shelter
      lit('1').eq(any(a_t[:project_types]))
    end

    def innovative
      lit('12').eq(any(a_t[:project_types]))
    end

    def total
      Arel.sql('1=1')
    end

    # Populations
    def adults
      a_t[:age].gteq(18).or(a_t[:emancipated].eq(true))
    end

    def children
      a_t[:age].lt(18).and(a_t[:emancipated].eq(false))
    end

    def households
      @households ||=
        {}.tap do |hash|
          report_client_scope.each do |client|
            hap_client = client.universe_membership
            hap_client.household_ids.each do |h_id|
              hash[h_id] ||= []
              hash[h_id] << {
                client_id: client.id,
                head: hap_client.head_of_household_for.include?(h_id),
                age: hap_client.age,
              }
            end
          end
        end
    end

    def families_with_children
      @families_with_children ||= households.
        select { |_, v| v.size > 1 && v.any? { |client| client[:age] < 18 } }.
        map { |_, v| v.map { |client| client[:client_id] } }.
        flatten
      a_t[:id].in(@families_with_children)
    end

    def only_head_of_families_with_children
      @head_of_families_with_children ||= households.
        select { |_, v| v.size > 1 && v.any? { |client| client[:age] < 18 } }.
        map { |_, v| v.select { |client| client[:head] }.map { |client| client[:client_id] } }.
        flatten
      a_t[:id].in(@head_of_families_with_children)
    end

    def adult_only_households
      @adult_only_households ||= households.
        select { |_, v| v.size > 1 && v.all? { |client| client[:age] >= 18 } }.
        map { |_, v| v.map { |client| client[:client_id] } }.
        flatten
      a_t[:id].in(@adult_only_households)
    end

    def only_head_of_adult_only_households
      @head_of_adult_only_households ||= households.
        select { |_, v| v.size > 1 && v.all? { |client| client[:age] >= 18 } }.
        map { |_, v| v.select { |client| client[:head] }.map { |client| client[:client_id] } }.
        flatten
      a_t[:id].in(@head_of_adult_only_households)
    end

    def individuals
      @individuals ||= households.
        select { |_, v| v.size == 1 }.
        map { |_, v| v.map(&:first) }.
        flatten
      a_t[:id].in(@individuals)
    end

    def under_sixty
      a_t[:age].lt(60)
    end

    def sixty_plus
      a_t[:age].gteq(60)
    end

    def veterans
      adults.and(a_t[:veteran].eq(true))
    end

    def mh_services
      a_t[:mental_health].eq(true)
    end

    def da_services
      a_t[:substance_abuse].eq(true)
    end

    def dv_services
      a_t[:domestic_violence].eq(true)
    end

    def employed_at_start
      a_t[:income_at_start].not_eq(nil).
        and(a_t[:income_at_start].gt(0))
    end

    def gained_employment
      a_t[:income_at_start].eq(nil).
        or(a_t[:income_at_start].eq(0)).
        and(
          a_t[:income_at_exit].not_eq(nil).
            and(a_t[:income_at_exit].gt(0)),
        )
    end

    def homeless
      a_t[:homeless].eq(true)
    end
  end
end
