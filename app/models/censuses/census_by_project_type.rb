module Censuses
  class CensusByProjectType < Base
    def for_date_range start_date, end_date, scope: nil
      load_associated_records()
      service_days = fetch_service_days(start_date.to_date - 1.day, end_date, scope)
      {}.tap do |item|
        service_days_by_project_type = service_days.group_by do |s|
          [s['date'], @project_types.select{ |k,v| v.include? s['project_type'] }.keys.first]
        end
        service_days_by_project_type.each do |k,entries|
          date, project_type = k
          if date == start_date.to_date - 1.day
            next
          end
          count = entries.map{ |m| m['count_all']}.reduce( :+ )
          yesterday_count = service_days_by_project_type[[date - 1.day, project_type]].map{|m| m['count_all']}.compact.reduce( :+ )
          item[project_type] ||= {}
          item[project_type][:datasets] ||= []
          item[project_type][:datasets][0] ||= {
            label: 'Client Count'
          }
          item[project_type][:title] ||= {}
          item[project_type][:title][:display] ||= true
          item[project_type][:title][:text] ||= "#{GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES[project_type]}" 
          item[project_type][:datasets][0][:data] ||= []
          item[project_type][:datasets][0][:data] << {x: date, y: count, yesterday: yesterday_count}
        end
      end
    end

    def detail_name project_type
      "#{GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES[project_type.to_sym]} on"
    end

    private def fetch_service_days start_date, end_date, scope
      scope ||= GrdaWarehouse::CensusByProjectType
      at = scope.arel_table
      relation = scope.
        where(ProjectType: @project_types.values.flatten.uniq).
        where( at[:date].between start_date.to_date..end_date.to_date ).
        group(:date, :ProjectType).
        select( at[:date], at[:ProjectType].as('project_type'), at[:client_count].sum.as('count_all') ).
        order(date: :desc)
      service_days = relation_as_report relation
    end
  end
end