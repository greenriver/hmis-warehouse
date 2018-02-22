module GrdaWarehouse::WarehouseReports
  class InitiativeReport < Base
    include ArelHelper
    # A simple method to get some test parameters
    def default_params
      {"initiative_name"=>"RRH",
       "start"=>"2018-01-22",
       "end"=>"2018-02-22",
       "comparison_start"=>"2017-01-22",
       "comparison_end"=>"2017-02-22",
       "projects"=>[4, 9, 10, 2],
       "sub_population"=>"family"}
    end

    def run!
      setup()
      involved_genders()
      involved_project_types()
      gender_breakdowns_by_project_type()
      gender_breakdowns_by_project()

      complete()
    end

    def involved_project_types
      p_types = report_scope.distinct.pluck(:project_type)
      p_types += comparison_scope.distinct.pluck(:project_type)
      @data.merge!(involved_project_types: p_types.uniq.map{|m| ::HUD.project_type_brief(m)})
    end

    def involved_genders
      genders = report_scope.distinct.pluck(c_t[:Gender].to_sql)
      genders += comparison_scope.distinct.pluck(c_t[:Gender].to_sql)
      @data.merge!(involved_genders: genders.uniq.map{|m| ::HUD.gender(m)})
    end

    def gender_breakdowns_by_project_type
      columns = {
        project_type: :project_type, 
        gender: c_t[:Gender].to_sql, 
        client_id: :client_id, 
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        gender_breakdowns_by_project_type: :report_scope,
        comparison_gender_breakdowns_by_project_type: :comparison_scope,
      }
      groups.each do |key, r_scope|
        # breakdowns = send(r_scope).distinct.group(:project_type, c_t[:Gender]).count(c_t[:Gender].to_sql).map do |(project_type, gender), count|
        #     [[::HUD.project_type_brief(project_type), ::HUD.gender(gender)], count]
        #   end.to_h
        data = send(r_scope).distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          "#{::HUD.project_type_brief(row[:project_type])}__#{::HUD.gender(row[:gender])}"
        end
        counts = data.map do |k, group|
          [k, group.size]
        end.to_h
        support = {
          headers: ['Client ID', 'First Name', 'Last Name']
        }
        support[:counts] = data.map do |k, group|
          [
            k, 
            group.map{|row| [row[:client_id], row[:last_name], row[:first_name]]}
          ]
        end.to_h
        @data.merge!(key => counts)
        @support.merge!(key => support)
      end
    end

    def gender_breakdowns_by_project
      {
        gender_breakdowns_by_project: :report_scope,
        comparison_gender_breakdowns_by_project: :comparison_scope,
      }.each do |key, r_scope|
        breakdowns = send(r_scope).distinct.group(p_t[:id], c_t[:Gender]).count(c_t[:Gender].to_sql).map do |(project_id, gender), count|
            [[project_name(project_id), ::HUD.gender(gender)], count]
          end.to_h
        @data.merge!(key => breakdowns)
      end
    end

    def enrollment_scope
      @enrollment_scope ||= enrollment_source.send(@sub_population).
        joins(:project, :client).
        merge(project_scope)      
    end

    def project_scope
      @project_scope ||= if @project_ids.any?
        project_source.where(id: @project_ids)
      else
        project_source
      end
    end

    def report_scope
      @report_scope ||= enrollment_scope.
        with_service_between(
          start_date: @start, 
          end_date: @end,
          service_scope: sub_population_service_scope
        )
    end

    def comparison_scope
      @comparison_scope ||= enrollment_scope.
        with_service_between(
          start_date: @comparison_start, 
          end_date: @comparison_end,
          service_scope: sub_population_service_scope
        )
    end

    def sub_population_service_scope
      case @sub_population
      when :youth, :children, :adult
        @sub_population
      when :parenting_youth
        :youth
      when :parenting_children
        :children
      when :individual_adults
        :adult
      else
        :current_scope
      end
    end

    def setup
      self.started_at = Time.now
      self.data = @data = {}
      @support = {}
      parameters = OpenStruct.new(self.parameters.with_indifferent_access)
      @start = parameters.start
      @end = parameters.end
      @comparison_start = parameters.comparison_start
      @comparison_end = parameters.comparison_end
      @project_ids = parameters.projects
      @sub_population = parameters.sub_population.to_sym

      save!
    end

    def complete
      self.data = @data.merge(support: @support)
      self.finished_at = Time.now
      save!
    end

    def client_scope
      GrdaWarehouse::Hud::Client
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end

    def project_name id
      @projects ||= project_source.all.pluck(:id, :ProjectName).to_h
      @projects[id]
    end

    def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def sub_population_scope
      if GrdaWarehouse::WarehouseReports::Dashboard::Base.
        available_sub_populations.values.include?(@sub_population)
        @sub_population
      else
        :none
      end
    end

  end
end