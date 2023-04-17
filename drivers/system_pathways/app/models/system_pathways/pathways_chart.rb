###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways
  class PathwaysChart
    include ArelHelper
    attr_accessor :report, :filter
    def initialize(report:, filter:)
      self.report = report
      self.filter = filter
    end

    def clients
      @report.clients.joins(:enrollments)
    end

    def filtered_clients
      scope = clients
      scope = filter_for_race(scope)
      scope = filter_for_ethnicity(scope)
      scope = filter_for_veteran_status(scope)
      scope = filter_for_ce_involvement(scope)
      scope
    end

    private def filter_for_race(scope)
      return scope unless @filter.races.present?

      race_scope = nil
      @filter.races.each do |column|
        next if column == 'MultiRacial'

        race_scope = add_alternative(race_scope, SystemPathways::Client.where(column.underscore.to_sym => true))
      end

      # Include anyone who has more than one race listed, anded with any previous alternatives
      race_scope ||= scope
      race_scope = race_scope.where(id: multi_racial_clients.select(:id)) if @filter.races.include?('MultiRacial')
      scope.merge(race_scope)
    end

    private def multi_racial_clients
      # Looking at all races with responses of 1, where we have a sum > 1
      a_t = SystemPathways::Client.arel_table
      columns = [
        :am_ind_ak_native,
        :asian,
        :black_af_american,
        :native_hi_pacific,
        :white,
      ].map do |col|
        "CASE WHEN #{a_t[col].to_sql} THEN 1 ELSE 0 END"
      end
      scope.where(Arel.sql(columns.join(' + ')).between(2..98))
    end

    private def add_alternative(scope, alternative)
      if scope.nil?
        alternative
      else
        scope.or(alternative)
      end
    end

    private def filter_for_ethnicity(scope)
      return scope unless @filter.ethnicities.present?

      scope.where(ethnicity: @filter.ethnicities)
    end

    private def filter_for_veteran_status(scope)
      return scope unless @filter.veteran_statuses.present?

      scope.where(veteran_status: @filter.veteran_statuses)
    end

    private def filter_for_ce_involvement(scope)
      return scope unless @filter.involves_ce

      scope.where(ce: true)
    end

    def transition_clients(from, to)
      if to&.include?('destination')
        final_transition_clients(from, to)
      else
        from_project_type = HudUtility.project_type_number(from)
        to_project_type = HudUtility.project_type_number(to)
        filtered_clients.joins(:enrollments).
          merge(SystemPathways::Enrollment.where(from_project_type: from_project_type, project_type: to_project_type)).
          distinct
      end
    end

    def final_transition_clients(from, destination_category)
      from_project_type = HudUtility.project_type_number(from)
      filtered_clients.where(destination_category => true).
        joins(:enrollments).
        merge(SystemPathways::Enrollment.where(from_project_type: from_project_type)).
        distinct
    end

    def node_clients(node)
      if node&.include?('destination')
        filtered_clients.where(node => true)
      else
        to_project_type = HudUtility.project_type_number(node)
        filtered_clients.joins(:enrollments).
          merge(SystemPathways::Enrollment.where(project_type: to_project_type)).
          distinct
      end
    end

    def chart_data
      [
        # // System -> ES
        {
          'source': 'Served by Homeless System',
          'target': 'ES',
          'value': transition_clients(nil, 'ES').count,
        },
        # // ES -> Destinations (Non-Permanent)
        {
          'source': 'ES',
          'target': 'Institutional Destinations',
          'value': transition_clients('ES', 'destination_institutional').count,
        },
        {
          'source': 'ES',
          'target': 'Temporary Destinations',
          'value': transition_clients('ES', 'destination_temporary').count,
        },
        {
          'source': 'ES',
          'target': 'Unknown/Other',
          'value': transition_clients('ES', 'destination_other').count,
        },
        {
          'source': 'ES',
          'target': 'Homeless',
          'value': transition_clients('ES', 'destination_homeless').count,
        },
        # // ES -> Other types
        {
          'source': 'ES',
          'target': 'PH - RRH',
          'value': transition_clients('ES', 'PH - RRH').count,
        },
        {
          'source': 'ES',
          'target': 'PH - PSH',
          'value': transition_clients('ES', 'PH - PSH').count,
        },
        {
          'source': 'ES',
          'target': 'TH',
          'value': transition_clients('ES', 'TH').count,
        },
        # // Remaining types from system
        {
          'source': 'Served by Homeless System',
          'target': 'PH - RRH',
          'value': transition_clients(nil, 'PH - RRH').count,
        },
        {
          'source': 'Served by Homeless System',
          'target': 'PH - PSH',
          'value': transition_clients(nil, 'PH - PSH').count,
        },
        {
          'source': 'Served by Homeless System',
          'target': 'TH',
          'value': transition_clients(nil, 'TH').count,
        },
        {
          'source': 'Served by Homeless System',
          'target': 'SO',
          'value': transition_clients(nil, 'SO').count,
        },
        # // SO -> ES
        {
          'source': 'SO',
          'target': 'ES',
          'value': transition_clients('SO', 'ES').count,
        },
        {
          'source': 'SO',
          'target': 'SH',
          'value': transition_clients('SO', 'SH').count,
        },
        {
          'source': 'SO',
          'target': 'PH - RRH',
          'value': transition_clients('SO', 'PH - RRH').count,
        },
        {
          'source': 'SO',
          'target': 'PH - PSH',
          'value': transition_clients('SO', 'PH - PSH').count,
        },
        {
          'source': 'SO',
          'target': 'TH',
          'value': transition_clients('SO', 'TH').count,
        },
        # // TH -> RRH
        {
          'source': 'TH',
          'target': 'PH - RRH',
          'value': transition_clients('TH', 'PH - RRH').count,
        },
        # // TH -> PSH
        {
          'source': 'TH',
          'target': 'PH - PSH',
          'value': transition_clients('TH', 'PH - PSH').count,
        },
        # // RRH -> PSH
        {
          'source': 'PH - RRH',
          'target': 'PH - PSH',
          'value': transition_clients('PH - RRH', 'PH - PSH').count,
        },
        # // RRH to destinations
        {
          'source': 'PH - RRH',
          'target': 'Temporary Destinations',
          'value': transition_clients('PH - RRH', 'destination_temporary').count,
        },
        {
          'source': 'PH - RRH',
          'target': 'Unknown/Other',
          'value': transition_clients('PH - RRH', 'destination_other').count,
        },
        {
          'source': 'PH - RRH',
          'target': 'Homeless',
          'value': transition_clients('PH - RRH', 'destination_homeless').count,
        },
        {
          'source': 'PH - RRH',
          'target': 'Permanent Destinations',
          'value': transition_clients('PH - RRH', 'destination_permanent').count,
        },
        # // PSH to destinations
        {
          'source': 'PH - PSH',
          'target': 'Homeless',
          'value': transition_clients('PH - PSH', 'destination_homeless').count,
        },
        {
          'source': 'PH - PSH',
          'target': 'Unknown/Other',
          'value': transition_clients('PH - PSH', 'destination_other').count,
        },
        {
          'source': 'PH - PSH',
          'target': 'Permanent Destinations',
          'value': transition_clients('PH - PSh', 'destination_permanent').count,
        },

        # // TH to destinations
        {
          'source': 'TH',
          'target': 'Temporary Destinations',
          'value': transition_clients('TH', 'destination_temporary').count,
        },
        {
          'source': 'TH',
          'target': 'Permanent Destinations',
          'value': transition_clients('TH', 'destination_permanent').count,
        },
        # // other pathways to destinations
        {
          'source': 'SO',
          'target': 'Institutional Destinations',
          'value': transition_clients('SO', 'destination_institutional').count,
        },
        {
          'source': 'SO',
          'target': 'Temporary Destinations',
          'value': transition_clients('SO', 'destination_temporary').count,
        },
        {
          'source': 'SO',
          'target': 'Unknown/Other',
          'value': transition_clients('SO', 'destination_other').count,
        },
        {
          'source': 'SO',
          'target': 'Homeless',
          'value': transition_clients('SO', 'destination_homeless').count,
        },
        {
          'source': 'SO',
          'target': 'Permanent Destinations',
          'value': transition_clients('SO', 'destination_permanent').count,
        },

        # // returns
        {
          'source': 'Permanent Destinations',
          'target': 'Returns to Homelessness',
          'value': 4,
        },
        # // ES -> Permanent destinations
        {
          'source': 'ES',
          'target': 'Permanent Destinations',
          'value': transition_clients('ES', 'destination_permanent').select(:client_id).count,
        },
      ]
    end

    def target_colors
      {
        'ES': '#85B5B2',
        'SH': '#85B5B2',
        'Institutional Destinations': '#808080',
        'Temporary Destinations': '#808080',
        'Unknown/Other': '#808080',
        'Homeless': '#808080',
        'Returns': '#967762',
        'PH - RRH': '#D1605E',
        'TH': '#A77C9F',
        'PH - PSH': '#E7CA60',
        'Other Pathways': '#E49344',
        'Permanent Destinations': '#6A9F58',
      }
    end

    def node_weights
      {
        'ES': -1,
        'SH': -1,
        'PH - RRH': 0,
        'PH - PSH': 11,
        'TH': 2,
        'Other Pathways': 5,
        'Homeless': 3,
        'Unknown/Other': 4,
        'Temporary Destinations': 5,
        'Institutional Destinations': 6,
        'Permanent Destinations': 10,
      }
    end
  end
end
