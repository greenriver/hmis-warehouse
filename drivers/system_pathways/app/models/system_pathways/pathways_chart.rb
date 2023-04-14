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
      from_project_type = HudUtility.project_type_number(from)
      to_project_type = HudUtility.project_type_number(to)
      filtered_clients.joins(:enrollments).
        merge(SystemPathways::Enrollment.where(from_project_type: from_project_type, project_type: to_project_type))
    end

    def final_transition_clients(from, destination_category)
      from_project_type = HudUtility.project_type_number(from)
      filtered_clients.where(destination_category => true).
        joins(:enrollments).
        merge(SystemPathways::Enrollment.where(from_project_type: from_project_type))
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
          'value': final_transition_clients('ES', 'destination_institutional').count,
        },
        {
          'source': 'ES',
          'target': 'Temporary Destinations',
          'value': final_transition_clients('ES', 'destination_temporary').count,
        },
        {
          'source': 'ES',
          'target': 'Unknown/Other',
          'value': final_transition_clients('ES', 'destination_other').count,
        },
        {
          'source': 'ES',
          'target': 'Homeless',
          'value': final_transition_clients('ES', 'destination_homeless').count,
        },
        # // ES -> Other types
        {
          'source': 'ES',
          'target': 'RRH',
          'value': transition_clients('ES', 'PH - RRH').count,
        },
        {
          'source': 'ES',
          'target': 'PSH',
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
          'target': 'RRH',
          'value': transition_clients(nil, 'PH - RRH').count,
        },
        {
          'source': 'Served by Homeless System',
          'target': 'PSH',
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
        # // TH -> RRH
        {
          'source': 'TH',
          'target': 'RRH',
          'value': transition_clients('TH', 'PH - RRH').count,
        },
        # // TH -> PSH
        {
          'source': 'TH',
          'target': 'PSH',
          'value': transition_clients('TH', 'PH - PSH').count,
        },
        # // RRH -> PSH
        {
          'source': 'RRH',
          'target': 'PSH',
          'value': transition_clients('PH - RRH', 'PH - PSH').count,
        },
        # // RRH to destinations
        {
          'source': 'RRH',
          'target': 'Institutional Destinations',
          'value': transition_clients('TH', 'PH - RRH').count,
        },
        {
          'source': 'RRH',
          'target': 'Temporary Destinations',
          'value': final_transition_clients('PH - RRH', 'destination_temporary').count,
        },
        {
          'source': 'RRH',
          'target': 'Unknown/Other',
          'value': final_transition_clients('PH - RRH', 'destination_other').count,
        },
        {
          'source': 'RRH',
          'target': 'Homeless',
          'value': final_transition_clients('PH - RRH', 'destination_homeless').count,
        },
        {
          'source': 'RRH',
          'target': 'Permanent Destinations',
          'value': final_transition_clients('PH - RRH', 'destination_permanent').count,
        },
        # // PSH to destinations
        {
          'source': 'PSH',
          'target': 'Homeless',
          'value': final_transition_clients('PH - PSH', 'destination_homeless').count,
        },
        {
          'source': 'PSH',
          'target': 'Unknown/Other',
          'value': final_transition_clients('PH - PSH', 'destination_other').count,
        },
        {
          'source': 'PSH',
          'target': 'Permanent Destinations',
          'value': final_transition_clients('PH - PSh', 'destination_permanent').count,
        },

        # // TH to destinations
        {
          'source': 'TH',
          'target': 'Temporary Destinations',
          'value': final_transition_clients('TH', 'destination_temporary').count,
        },
        {
          'source': 'TH',
          'target': 'Permanent Destinations',
          'value': final_transition_clients('TH', 'destination_permanent').count,
        },
        # // other pathways to destinations
        {
          'source': 'SO',
          'target': 'Permanent Destinations',
          'value': final_transition_clients('SO', 'destination_permanent').count,
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
          'value': final_transition_clients('ES', 'destination_permanent').count,
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
        'RRH': '#D1605E',
        'TH': '#A77C9F',
        'PSH': '#E7CA60',
        'Other Pathways': '#E49344',
        'Permanent Destinations': '#6A9F58',
      }
    end

    def node_weights
      {
        'ES': -1,
        'SH': -1,
        'RRH': 0,
        'PSH': 11,
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
