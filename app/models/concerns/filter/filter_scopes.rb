###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filter::FilterScopes
  extend ActiveSupport::Concern
  included do
    private def filter_for_user_access(scope)
      scope.joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(@filter.user))
    end

    private def filter_for_range(scope)
      scope.open_between(start_date: @filter.start_date, end_date: @filter.end_date).
        with_service_between(start_date: @filter.start_date, end_date: @filter.end_date)
    end

    private def filter_for_cocs(scope)
      return scope unless @filter.coc_codes.present?

      scope.joins(project: :project_cocs).
        merge(GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: @filter.coc_codes))
    end

    private def filter_for_household_type(scope)
      return scope unless @filter.household_type.present? && @filter.household_type != :all

      case @filter.household_type
      when :without_children
        scope.adult_only_households
      when :with_children
        scope.adults_with_children
      when :only_children
        scope.child_only_households
      end
    end

    private def filter_for_head_of_household(scope)
      return scope unless @filter.hoh_only

      scope.where(she_t[:head_of_household].eq(true))
    end

    private def age_calculation
      nf(
        'AGE',
        [
          nf(
            'GREATEST',
            [
              she_t[:first_date_in_program],
              @filter.start_date,
            ],
          ),
          c_t[:DOB],
        ],
      )
    end

    private def filter_for_age(scope)
      # The age ranges will be strings if we had saved them in the db, so we map to symbols
      age_ranges = @filter.age_ranges.select(&:present?).map(&:to_sym)
      return scope unless age_ranges.present? && (@filter.available_age_ranges.values & age_ranges).present?

      # Or'ing ages is very slow, instead we'll build up an acceptable
      # array of ages
      ages = []
      ages += (0..17).to_a if age_ranges.include?(:under_eighteen)
      ages += (18..24).to_a if age_ranges.include?(:eighteen_to_twenty_four)
      ages += (25..29).to_a if age_ranges.include?(:twenty_five_to_twenty_nine)
      ages += (30..39).to_a if age_ranges.include?(:thirty_to_thirty_nine)
      ages += (40..49).to_a if age_ranges.include?(:forty_to_forty_nine)
      ages += (50..54).to_a if age_ranges.include?(:fifty_to_fifty_four)
      ages += (55..59).to_a if age_ranges.include?(:fifty_five_to_fifty_nine)
      ages += (60..61).to_a if age_ranges.include?(:sixty_to_sixty_one)
      ages += (62..110).to_a if age_ranges.include?(:over_sixty_one)

      scope.joins(:client).where(
        Arel.sql("EXTRACT(YEAR FROM #{age_calculation.to_sql})").in(ages),
      )
    end

    private def filter_for_gender(scope)
      return scope unless @filter.genders.present?

      scope.joins(:client).where(c_t[:Gender].in(@filter.genders))
    end

    private def filter_for_race(scope)
      return scope unless @filter.races.present?

      keys = @filter.races
      race_scope = nil
      race_scope = add_alternative(race_scope, race_alternative(:AmIndAKNative)) if keys.include?('AmIndAKNative')
      race_scope = add_alternative(race_scope, race_alternative(:Asian)) if keys.include?('Asian')
      race_scope = add_alternative(race_scope, race_alternative(:BlackAfAmerican)) if keys.include?('BlackAfAmerican')
      race_scope = add_alternative(race_scope, race_alternative(:NativeHIOtherPacific)) if keys.include?('NativeHIOtherPacific')
      race_scope = add_alternative(race_scope, race_alternative(:White)) if keys.include?('White')
      race_scope = add_alternative(race_scope, race_alternative(:RaceNone)) if keys.include?('RaceNone')

      # Include anyone who has more than one race listed, anded with any previous alternatives
      race_scope ||= scope
      race_scope = race_scope.where(id: multi_racial_clients.select(:id)) if keys.include?('MultiRacial')

      scope.merge(race_scope)
    end

    private def multi_racial_clients
      # Looking at all races with responses of 1, where we have a sum > 1
      columns = [
        c_t[:AmIndAKNative],
        c_t[:Asian],
        c_t[:BlackAfAmerican],
        c_t[:NativeHIOtherPacific],
        c_t[:White],
      ]
      report_scope_source.joins(:client).
        where(Arel.sql(columns.map(&:to_sql).join(' + ')).between(2..98))
    end

    private def add_alternative(scope, alternative)
      if scope.present?
        scope.or(alternative)
      else
        alternative
      end
    end

    private def race_alternative(key)
      report_scope_source.joins(:client).where(c_t[key].eq(1))
    end

    private def filter_for_ethnicity(scope)
      return scope unless @filter.ethnicities.present?

      scope.joins(:client).where(c_t[:Ethnicity].in(@filter.ethnicities))
    end

    private def filter_for_veteran_status(scope)
      return scope unless @filter.veteran_statuses.present?

      scope.joins(:client).where(c_t[:VeteranStatus].in(@filter.veteran_statuses))
    end

    private def filter_for_project_type(scope, all_project_types: nil)
      return scope if all_project_types

      # Make this backwards compatible with a pre-set set of project_types.
      p_types = @project_types.presence || @filter.project_type_ids
      p_types += GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING[:ca] if @filter.coordinated_assessment_living_situation_homeless

      scope.in_project_type(p_types)
    end

    private def filter_for_projects(scope)
      return scope if @filter.project_ids.blank? && @filter.project_group_ids.blank?

      project_ids = if @filter.user.report_filter_visible?(:project_ids)
        @filter.project_ids || []
      else
        []
      end
      project_groups = GrdaWarehouse::ProjectGroup.where(id: @filter.project_group_ids)
      project_groups.each do |group|
        project_ids += group.projects.pluck(:id)
      end

      return scope if project_ids.blank?

      scope.in_project(project_ids.uniq).merge(GrdaWarehouse::Hud::Project.viewable_by(@filter.user))
    end

    private def filter_for_funders(scope)
      return scope if @filter.funder_ids.blank?
      return scope unless @filter.user.report_filter_visible?(:funder_ids)

      project_ids = GrdaWarehouse::Hud::Funder.viewable_by(@filter.user).
        where(Funder: @filter.funder_ids).
        joins(:project).
        select(p_t[:id])
      scope.in_project(project_ids)
    end

    private def filter_for_data_sources(scope)
      return scope if @filter.data_source_ids.blank?
      return scope unless @filter.user.report_filter_visible?(:data_source_ids)

      scope.in_data_source(@filter.data_source_ids).joins(:data_source).merge(GrdaWarehouse::DataSource.viewable_by(@filter.user))
    end

    private def filter_for_organizations(scope)
      return scope if @filter.organization_ids.blank?
      return scope unless @filter.user.report_filter_visible?(:organization_ids)

      scope.in_organization(@filter.organization_ids).merge(GrdaWarehouse::Hud::Organization.viewable_by(@filter.user))
    end

    private def filter_for_sub_population(scope)
      return scope unless @filter.sub_population.present?

      scope.public_send(@filter.sub_population)
    end

    private def filter_for_prior_living_situation(scope)
      return scope if @filter.prior_living_situation_ids.blank?

      scope.where(housing_status_at_entry: @filter.prior_living_situation_ids)
    end

    private def filter_for_destination(scope)
      return scope if @filter.destination_ids.blank?

      scope.where(destination: @filter.destination_ids)
    end

    private def filter_for_disabilities(scope)
      return scope if @filter.disabilities.blank?

      scope.joins(enrollment: :disabilities).
        merge(
          GrdaWarehouse::Hud::Disability.where(
            InformationDate: @filter.range,
            DisabilityType: @filter.disabilities,
            DisabilityResponse: GrdaWarehouse::Hud::Disability.positive_responses,
          ),
        )
    end

    private def filter_for_indefinite_disabilities(scope)
      return scope if @filter.indefinite_disabilities.blank?

      scope.joins(enrollment: :disabilities).
        merge(
          GrdaWarehouse::Hud::Disability.where(
            InformationDate: @filter.range,
            IndefiniteAndImpairs: @filter.indefinite_disabilities,
          ),
        )
    end

    private def filter_for_dv_status(scope)
      return scope if @filter.dv_status.blank?

      scope.joins(enrollment: :health_and_dvs).
        merge(
          GrdaWarehouse::Hud::HealthAndDv.where(
            InformationDate: @filter.range,
            DomesticViolenceVictim: @filter.dv_status,
          ),
        )
    end

    private def filter_for_chronic_status(scope)
      return scope unless @filter.chronic_status

      chronic_source = case GrdaWarehouse::Config.get(:chronic_definition).to_sym
      when :chronics
        GrdaWarehouse::Chronic
      when :hud_chronics
        GrdaWarehouse::HudChronic
      end
      max_date = chronic_source.where(date: @filter.range).maximum(:date)

      scope.where(client_id: chronic_source.where(date: max_date).select(:client_id))
    end

    # This needs to work correctly with project type filters, where it adds the
    # potentially additional type of CA, but only if LivingSituation (3.917.1) is
    # of a homeless type (6, 1, 18)
    private def filter_for_ca_homeless(scope)
      return scope unless @filter.coordinated_assessment_living_situation_homeless

      scope.joins(:enrollment).where(
        she_t[:computed_project_type].in(GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING[:ca]).
        and(e_t[:LivingSituation].in(HUD.homeless_situations(as: :prior))).
        or(she_t[:computed_project_type].in(@project_types)),
      )
    end

    private def filter_for_times_homeless(scope)
      return scope unless @filter.times_homeless_in_last_three_years.present?

      scope.joins(:enrollment).where(e_t[:TimesHomelessPastThreeYears].in(@filter.times_homeless_in_last_three_years))
    end
  end
end
