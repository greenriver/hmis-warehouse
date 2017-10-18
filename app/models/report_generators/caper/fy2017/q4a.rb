module ReportGenerators::CAPER::Fy2017
  # Project Identifiers in HMIS
  class Q4a < Base

    def run!
      if start_report(Reports::CAPER::Fy2017::Q4a.first)
        @answers = setup_questions()
        @support = @answers.deep_dup
        @all_clients = fetch_all_clients()
        if @all_clients.any?
          add_organization_names
          update_report_progress percent: 13
          add_organization_ids
          update_report_progress percent: 25
          add_project_names
          update_report_progress percent: 37
          add_project_ids
          update_report_progress percent: 50
          add_hmis_project_type
          update_report_progress percent: 63
          add_method_for_tracking_es
          update_report_progress percent: 75
          add_affiliation_with_residential_project
          update_report_progress percent: 88
          add_housing_project_ids
        end
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def fetch_all_clients
      columns = columnize(
        client_id:    sh_t, 
        project_id:   sh_t,
        project_name: sh_t,
        OrganizationName: o_t,
        OrganizationID:   o_t,
      ).merge({
        project_type: act_as_project_overlay
      })
      
      # FIXME this method is returning a structure grouped by client_id, but they are currently written all the data collection methods just chuck this structure and use the values
      # this format is maintained because it is used elsewhere, so most likely the data collection methods are doing it wrong
      all_client_scope.
        joins( { project: :organization }, :enrollment ).
        order(date: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.map do |enrollment|
          enrollment[:age] = age_for_report(dob: enrollment[:DOB], enrollment: enrollment)
          enrollment
        end.group_by do |row|
          row[:client_id]
        end
    end

    def service_histories
      @all_clients.values.flatten
    end

    def add_organization_names
      filtered = service_histories.uniq{ |h| h.values_at :OrganizationName, :client_id }
      sorted = filtered.sort do |a,b|
        c = a[:OrganizationName] <=> b[:OrganizationName]
        c = a[:client_id] <=> b[:client_id] if c == 0
        c
      end
      @answers[:q4a_b1][:value] = sorted.map{ |h| h[:OrganizationName] }.uniq.join(', ')
      @support[:q4a_b1][:support] = add_support(
        headers: ['Organization Name', 'Client ID'],
        data: sorted.map do |client|
          client.values_at :OrganizationName, :client_id
        end
      )
    end

    def add_organization_ids
      filtered = service_histories.uniq{ |h| h.values_at :OrganizationID, :client_id }
      sorted = filtered.sort do |a,b|
        c = a[:OrganizationID].to_i <=> b[:OrganizationID].to_i
        c = a[:client_id] <=> b[:client_id] if c == 0
        c
      end
      @answers[:q4a_b2][:value] = sorted.map{ |h| h[:OrganizationID] }.uniq.join(', ')
      @support[:q4a_b2][:support] = add_support(
        headers: ['Organization ID', 'Client ID'],
        data: sorted.map do |client|
          client.values_at :OrganizationID, :client_id
        end
      )
    end

    def add_project_names
      filtered = service_histories.uniq{ |h| h.values_at :project_name, :client_id }
      sorted = filtered.sort do |a,b|
        c = a[:project_name] <=> b[:project_name]
        c = a[:client_id] <=> b[:client_id] if c == 0
        c
      end
      sorted = service_histories.sort_by{ |h| h[:project_name] }
      @answers[:q4a_b3][:value] = sorted.map{ |h| h[:project_name] }.uniq.join(', ')
      @support[:q4a_b3][:support] = add_support(
        headers: ['Project Name', 'Client ID'],
        data: sorted.map do |client|
          client.values_at :project_name, :client_id
        end
      )
    end

    def add_project_ids
      filtered = service_histories.uniq{ |h| h.values_at :project_id, :client_id }
      sorted = filtered.sort do |a,b|
        c = a[:project_id].to_i <=> b[:project_id].to_i
        c = a[:client_id] <=> b[:client_id] if c == 0
        c
      end
      @answers[:q4a_b4][:value] = sorted.map{ |h| h[:project_id] }.uniq.join(', ')
      @support[:q4a_b4][:support] = add_support(
        headers: ['Project ID', 'Client ID'],
        data: sorted.map do |client|
          client.values_at :project_id, :client_id
        end
      )
    end

    def add_hmis_project_type
      filtered = service_histories.uniq{ |h| h.values_at :project_type, :project_id, :client_id }
      sorted = filtered.sort do |a, b|
        c = a[:project_type] <=> b[:project_type]
        c = a[:project_id] <=> b[:project_id] if c == 0
        c = a[:client_id] <=> b[:client_id] if c == 0
        c
      end
      @answers[:q4a_b5][:value] = sorted.map{ |h| h[:project_type] }.uniq.join(', ')
      @support[:q4a_b5][:support] = add_support(
        headers: ['Project ID', 'Project Type', 'Project Type Brief', 'Client ID'],
        data: sorted.map do |client|
          pi, pt, ci = client.values_at :project_id, :project_type, :client_id
          [ pi, pt, HUD.project_type_brief(pt), ci ]
        end
      )
    end

    def add_method_for_tracking_es
      filtered = service_histories.select{ |h| h[:project_type] == 1 }
      filtered = filtered.uniq{ |h| h.values_at :project_id, :client_id }
      sorted = filtered.sort do |a, b|
        c = a[:project_id] <=> b[:project_id]
        c = a[:client_id] <=> b[:client_id] if c == 0
        c
      end
      @answers[:q4a_b6][:value] = 'FIXME: this is supposed to be a 0 or a 3, but under what circumstances it is one or the other is beyond me'
      @support[:q4a_b6][:support] = add_support(
        headers: ['Project ID', 'Client ID'],
        data: filtered.map do |client|
          client.values_at :project_id, :client_id
        end
      )
    end

    def add_affiliation_with_residential_project
      filtered = service_histories.select{ |h| h[:project_type] == 6 }
      filtered = filtered.uniq{ |h| h.values_at :project_id, :client_id }
      sorted = filtered.sort do |a, b|
        c = a[:project_id] <=> b[:project_id]
        c = a[:client_id] <=> b[:client_id] if c == 0
        c
      end
      @answers[:q4a_b6][:value] = 'FIXME: this is supposed to be a 0 or a 1, but under what circumstances it is one or the other is beyond me'
      @support[:q4a_b6][:support] = add_support(
        headers: ['Project ID', 'Client ID'],
        data: filtered.map do |client|
          client.values_at :project_id, :client_id
        end
      )
    end

    def add_housing_project_ids
      filtered = service_histories.select{ |h| h[:project_type].in? GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS }
      filtered = filtered.uniq{ |h| h.values_at :project_type, :project_id, :client_id }
      sorted = filtered.sort do |a, b|
        c = a[:project_type] <=> b[:project_type]
        c = a[:project_id] <=> b[:project_id] if c == 0
        c = a[:client_id] <=> b[:client_id] if c == 0
        c
      end
      @answers[:q4a_b8][:value] = filtered.count
      @support[:q4a_b8][:support] = add_support(
        headers: ['Project ID', 'Project Type', 'Project Type Brief', 'Client ID'],
        data: sorted.map do |client|
          pi, pt, ci = client.values_at :project_id, :project_type, :client_id
          [ pi, pt, HUD.project_type_brief(pt), ci ]
        end
      )
    end


    def setup_questions
      {
        q4a_a1: {
          title:  nil,
          value: 'Organization Name',
        },
        q4a_a2: {
          title:  nil,
          value: 'Organization ID',
        },
        q4a_a3: {
          title:  nil,
          value: 'Project Name',
        },
        q4a_a4: {
          title:  nil,
          value: 'Project ID',
        },
        q4a_a5: {
          title:  nil,
          value: 'HMIS Project Type',
        },
        q4a_a6: {
          title:  nil,
          value: 'Method for Tracking ES',
        },
        q4a_a7: {
          title:  nil,
          value: 'Is the Services Only (HMIS Project Type 6) affiliated with a residential project?',
        },
        q4a_a8: {
          title:  nil,
          value: 'Identify the Project ID’s of the housing projects this project is affiliated with',
        },

        q4a_b1: {
          title:  'Organization Name',
          value: 0,
        },
        q4a_b2: {
          title:  'Organization ID',
          value: 0,
        },
        q4a_b3: {
          title:  'Project Name',
          value: 0,
        },
        q4a_b4: {
          title:  'Project ID',
          value: 0,
        },
        q4a_b5: {
          title:  'HMIS Project Type',
          value: 0,
        },
        q4a_b6: {
          title:  'Method for Tracking ES',
          value: 0,
        },
        q4a_b7: {
          title:  'Is the Services Only (HMIS Project Type 6) affiliated with a residential project?',
          value: 0,
        },
        q4a_b8: {
          title:  'Identify the Project ID’s of the housing projects this project is affiliated with',
          value: 0,
        },
      }
    end

  end
end