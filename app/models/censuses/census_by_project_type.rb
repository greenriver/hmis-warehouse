module Censuses
  class CensusByProjectType < Base
    def for_date_range start_date, end_date, scope: nil
      load_associated_records()
      service_days = fetch_service_days(start_date.to_date - 1.day, end_date, scope)
      {}.tap do |item|
        service_days_by_project_type = service_days.group_by do |s|
          [s['date'].to_date, @project_types.select{ |k,v| v.include? s['project_type'].to_i }.keys.first]
        end
        service_days_by_project_type.each do |k,entries|
          date, project_type = k
          date = date.to_date
          project_type = project_type
          if date == start_date.to_date - 1.day
            next
          end
          count = entries.map{ |m| m['count_all'].to_i}.reduce( :+ )
          yesterday_data = service_days_by_project_type[[date.to_date - 1.day, project_type]]
          yesterday_count = if yesterday_data.present?
              yesterday_data.map do|m| 
                m['count_all'].to_i
              end.compact.reduce( :+ )
            else
              0
            end
          item[project_type] ||= {}
          item[project_type][:datasets] ||= []
          item[project_type][:datasets][0] ||= {
            label: 'Client Count'
          }
          item[project_type][:title] ||= {}
          item[project_type][:title][:display] ||= true
          item[project_type][:title][:text] ||= GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES[project_type].to_s 
          item[project_type][:datasets][0][:data] ||= []
          item[project_type][:datasets][0][:data] << {x: date, y: count, yesterday: yesterday_count}
        end
      end
    end

    def for_date_range_combined start_date:, end_date:, scope: nil
      load_associated_records()
      service_days = fetch_service_days(start_date.to_date - 1.day, end_date, scope)
      colors = GrdaWarehouse::Hud::Project::PROJECT_TYPE_COLORS
      colors[:total] = 'rgba(35, 173, 211, 0.5)'
      titles = GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES
      titles[:total] = 'Total'
      totals = service_days.group_by do |m|
        m['date']
      end.map do |date, days| 
        {x: date, y: days.map{|d| d['count_all']}.sum}
      end.sort_by do |date| 
        date[:x] 
      end
      grouped = service_days.group_by do |m|
        HUD.project_type_brief(m['project_type']).downcase.to_sym
      end.map do |project_type, days|
        [
          project_type,
          days.map do |day|
            {x: day['date'], y: day['count_all']}
          end.sort_by do |date|
            date[:x]
          end
        ]
      end.to_h
      grouped[:total] = totals
      # Add some trend lines
      # min_date = totals.first[:x]
      # max_date = totals.last[:x]
      # grouped['Trend 1'] = [{x: min_date, y: 100}, {x: max_date, y: 250}]
      
      {}.tap do |data|
        grouped.each do |label, dates|
          data[:datasets] ||= []
          data[:datasets] << {
            label: titles[label],
            data: dates,
            borderColor: colors[label],
          }
          data[:labels] ||= []
          data[:labels] << label

          # Add some trend lines
          trend_line = ::LineFit.new
          y = dates.map{|m| m[:y]}
          x = (0...dates.count).to_a
          trend_line.setData(x,y)
          intercept, slope = trend_line.coefficients
          predicted_ys = trend_line.predictedYs
          trend_data = [
            {
              x: dates.first[:x],
              y: predicted_ys.first,
            },
            {
              x: dates.last[:x],
              y: predicted_ys.last,
            },
          ]
          trend_label = "#{titles[label]} trend"
          data[:datasets] << {
            label: trend_label,
            data: trend_data,
            pointStyle: 'cross',
            borderColor: colors[label],
            borderWidth: 2,
            pointRadius: 0,
          }
          data[:labels] << trend_label
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