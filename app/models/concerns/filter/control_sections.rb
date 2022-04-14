###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  Filter::ControlSections
  extend ActiveSupport::Concern
  included do
    def control_sections
      @control_sections ||= build_control_sections
    end

    protected def build_control_sections
      [
        build_general_control_section,
        build_coc_control_section,
        build_household_control_section,
        build_demographics_control_section,
        build_enrollment_control_section,
      ]
    end

    protected def build_general_control_section(include_comparison_period: true)
      ::Filters::UiControlSection.new(id: 'general').tap do |section|
        section.add_control(
          id: 'project_types',
          required: true,
          label: 'Population by Project Type',
          short_label: 'Project Type',
          value: describe_project_type_control_section,
        )
        section.add_control(
          id: 'coordinated_assessment_living_situation_homeless',
          label: 'Including CA homeless at entry?',
          value: @filter.coordinated_assessment_living_situation_homeless ? 'Yes' : nil,
          hint: "Including Coordinated Entry enrollments where the prior living situation is homeless (#{HUD.homeless_situations(as: :prior).to_sentence}) will include these clients even if they do not have an enrollment in one of the chosen project types.",
        )
        section.add_control(
          id: 'ce_cls_as_homeless',
          label: 'Including CA Current Living Situation Homeless',
          value: @filter.ce_cls_as_homeless ? 'Yes' : nil,
          hint: "Including Coordinated Entry enrollments where the client has at least two homeless current living situations (#{HUD.homeless_situations(as: :current).to_sentence}) within the report range. These clients will be included even if they do not have an enrollment in one of the chosen project types.",
        )
        section.add_control(
          id: 'reporting_period',
          required: true,
          value: @filter.date_range_words,
        )
        if include_comparison_period
          section.add_control(
            id: 'comparison_period',
            value: nil,
          )
        end
      end
    end

    protected def describe_project_type_control_section
      if @filter.chosen_project_types_only_homeless?
        'Only Homeless'
      elsif filter.project_type_codes.sort == GrdaWarehouse::Hud::Project::PROJECT_GROUP_TITLES.keys.map(&:to_s).sort
        'All'
      else
        @filter.chosen_project_types
      end
    end

    protected def build_coc_control_section(multi_coc = GrdaWarehouse::Config.get(:multi_coc_installation))
      title = if multi_coc
        'CoC & Funding'
      else
        'Projects & Funding'
      end
      ::Filters::UiControlSection.new(id: 'coc', title: title).tap do |section|
        if multi_coc
          section.add_control(
            id: 'coc_codes',
            label: 'CoC Codes',
            short_label: 'CoC',
            value: @filter.chosen_coc_codes,
          )
        end
        section.add_control(
          id: 'funding_sources',
          value: @filter.funder_names,
        )
        section.add_control(
          id: 'data_sources',
          value: @filter.data_source_names,
        )
        section.add_control(
          id: 'organizations',
          value: @filter.organization_names,
        )
        section.add_control(
          id: 'projects',
          value: @filter.project_names,
        )
        section.add_control(
          id: 'project_groups',
          value: @filter.project_groups,
        )
      end
    end

    protected def build_hoh_control_section
      ::Filters::UiControlSection.new(id: 'household').tap do |section|
        section.add_control(
          id: 'hoh_only',
          label: 'Only Heads of Household?',
          value: @filter.hoh_only ? 'HOH Only' : nil,
        )
      end
    end

    protected def build_household_control_section
      ::Filters::UiControlSection.new(id: 'household').tap do |section|
        section.add_control(id: 'household_type', required: true, value: @filter.household_type == :all ? nil : @filter.chosen_household_type)
        section.add_control(
          id: 'hoh_only',
          label: 'Only Heads of Household?',
          value: @filter.hoh_only ? 'HOH Only' : nil,
        )
      end
    end

    protected def build_demographics_control_section
      ::Filters::UiControlSection.new(id: 'demographics').tap do |section|
        section.add_control(
          id: 'sub_population',
          label: 'Sub-Population',
          short_label: 'Sub-Population',
          required: true,
          value: @filter.sub_population == :clients ? nil : @filter.chosen_sub_population,
        )
        section.add_control(
          id: 'races',
          value: @filter.chosen_races,
          short_label: 'Race',
        )
        section.add_control(
          id: 'ethnicities',
          value: @filter.chosen_ethnicities,
          short_label: 'Ethnicity',
        )
        section.add_control(
          id: 'age_ranges',
          value: @filter.chosen_age_ranges,
          short_label: 'Age',
        )
        section.add_control(
          id: 'genders',
          short_label: 'Gender',
          value: @filter.chosen_genders,
        )
        section.add_control(
          id: 'veteran_statuses',
          short_label: 'Veteran Status',
          value: @filter.chosen_veteran_statuses,
        )
        section.add_control(
          id: 'times_homeless_in_last_three_years',
          short_label: 'Times Homeless in Past 3 Years',
          value: @filter.times_homeless_in_last_three_years,
        )
      end
    end

    protected def build_enrollment_control_section
      ::Filters::UiControlSection.new(id: 'enrollment').tap do |section|
        section.add_control(
          id: 'prior_living_situations',
          value: @filter.chosen_prior_living_situations,
        )
        section.add_control(
          id: 'destinations',
          value: @filter.chosen_destinations,
        )
      end
    end

    protected def add_demographic_disabilities_control_section
      section = build_demographics_control_section

      section.add_control(
        id: 'disabilities',
        value: @filter.chosen_disabilities,
        label: 'Disability Type',
      )
      section.add_control(
        id: 'indefinite_disabilities',
        value: @filter.chosen_indefinite_disabilities,
        label: 'Indefinite and Impairing?',
      )
      section.add_control(
        id: 'dv_status',
        value: @filter.chosen_dv_status,
        label: 'DV Status',
        hint: 'DV status is limited to occurrences that were reported during the chosen range indicating they had occurred within the past year.',
      )
      section.add_control(
        id: 'chronic_status',
        label: 'Chronically Homeless',
        value: @filter.chronic_status ? 'Chronically Homeless' : nil,
        hint: 'Chronically Homeless at Entry as defined in the HUD HMIS Glossary.',
      )
      section
    end
  end
end
