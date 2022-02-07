###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

    def token_expired
      updated_at < 3.months.ago
    end

    def run!
      setup()
      involved_genders()
      involved_project_types()
      involved_projects()
      involved_zipcodes()
      client_counts_by_project_type()
      client_counts_by_project()
      gender_breakdowns_by_project_type()
      gender_breakdowns_by_project()
      veteran_breakdowns_by_project_type()
      veteran_breakdowns_by_project()
      ethnicity_breakdowns_by_project_type()
      ethnicity_breakdowns_by_project()
      race_breakdowns_by_project_type()
      race_breakdowns_by_project()
      age_breakdowns_by_project_type()
      age_breakdowns_by_project()
      length_of_stay_breakdowns_by_project_type()
      length_of_stay_breakdowns_by_project()
      living_situation_breakdowns_by_project_type()
      living_situation_breakdowns_by_project()
      income_at_entry_breakdowns_by_project_type()
      income_at_entry_breakdowns_by_project()
      income_most_recent_breakdowns_by_project_type()
      income_most_recent_breakdowns_by_project()
      date_counts_by_project_type()
      date_counts_by_project()
      destination_breakdowns_by_project_type()
      destination_breakdowns_by_project()
      zip_breakdowns_by_project_type()
      zip_breakdowns_by_project()

      set_token()
      complete()
    end

    def involved_projects
      projects = project_scope.pluck(:id, :ProjectName).to_h
      @data.merge!(involved_projects: projects)
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

    def involved_zipcodes
      zips = report_scope.joins(:enrollment).distinct.pluck(e_t[:LastPermanentZIP].to_sql)
      zips += comparison_scope.joins(:enrollment).distinct.pluck(e_t[:LastPermanentZIP].to_sql)
      @data.merge!(involved_zipcodes: zips.uniq)
    end

    def date_counts_by_project_type
      columns = {
        project_type: :project_type,
        date: shs_t[:date].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        date_counts_by_project_type: :report_scope,
        comparison_date_counts_by_project_type: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = {}
        send(r_scope).joins(:service_history_services).
          distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          [row[:project_type], row[:date]]
        end.each do |(project_type, date), days|
          data_key = "#{::HUD.project_type_brief(project_type)}__#{date}"
          data[data_key] = days
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def date_counts_by_project
      columns = {
        project_id: p_t[:id].to_sql,
        date: shs_t[:date].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        date_counts_by_project: :report_scope,
        comparison_date_counts_by_project: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = {}
        send(r_scope).joins(:service_history_services).
          distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          [row[:project_id], row[:date]]
        end.each do |(project_id, date), days|
          data_key = "#{project_id}__#{date}"
          data[data_key] = days
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def client_counts_by_project_type
      columns = {
        project_type: :project_type,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        client_counts_by_project_type: :report_scope,
        comparison_client_counts_by_project_type: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = send(r_scope).distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          "#{::HUD.project_type_brief(row[:project_type])}__count"
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def client_counts_by_project
      columns = {
        project_id: p_t[:id].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        client_counts_by_project: :report_scope,
        comparison_client_counts_by_project: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = send(r_scope).distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          "#{row[:project_id]}__count"
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def destination_breakdowns_by_project_type
      columns = {
        project_type: :project_type,
        destination: :destination,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        destination_breakdowns_by_project_type: :report_scope,
        comparison_destination_breakdowns_by_project_type: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = send(r_scope).where.not(destination: nil).
          distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          "#{::HUD.project_type_brief(row[:project_type])}__#{row[:destination]}"
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def destination_breakdowns_by_project
      columns = {
        project_id: p_t[:id].to_sql,
        destination: :destination,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        destination_breakdowns_by_project: :report_scope,
        comparison_destination_breakdowns_by_project: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = send(r_scope).where.not(destination: nil).
          distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          "#{row[:project_id]}__#{row[:destination]}"
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def zip_breakdowns_by_project_type
      columns = {
        project_type: :project_type,
        zipcode: e_t[:LastPermanentZIP].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        zip_breakdowns_by_project_type: :report_scope,
        comparison_zip_breakdowns_by_project_type: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = send(r_scope).joins(:enrollment).
          where.not(Enrollment: {LastPermanentZIP: nil}).
          distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          "#{::HUD.project_type_brief(row[:project_type])}__#{row[:zipcode].first(5)}"
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def zip_breakdowns_by_project
      columns = {
        project_id: p_t[:id].to_sql,
        zipcode: e_t[:LastPermanentZIP].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        zip_breakdowns_by_project: :report_scope,
        comparison_zip_breakdowns_by_project: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = send(r_scope).joins(:enrollment).
          where.not(Enrollment: {LastPermanentZIP: nil}).
          distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          "#{row[:project_id]}__#{row[:zipcode].first(5)}"
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def income_most_recent_breakdowns_by_project_type
      columns = {
        project_type: :project_type,
        income: ib_t[:TotalMonthlyIncome].to_sql,
        information_date: ib_t[:InformationDate].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        income_most_recent_breakdowns_by_project_type: :report_scope,
        comparison_income_most_recent_breakdowns_by_project_type: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = {}
        all_incomes = {}
        send(r_scope).joins(enrollment: :income_benefits).
          distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          [row[:project_type], row[:client_id]]
        end.each do |(project_type, client_id), incomes|
          row = incomes.sort_by{|row| row[:information_date]}.last
          GrdaWarehouse::Hud::IncomeBenefit.income_ranges.each do |income_key, income_bucket|
            data_key = "#{::HUD.project_type_brief(row[:project_type])}__#{income_key}"
            data[data_key] ||= []
            data[data_key] << row if income_bucket[:range].include?(row[:income])
          end
          all_incomes[project_type] ||= []
          most_recent_income = incomes.sort_by{|row| row[:information_date]}.last[:income] || 0
          all_incomes[project_type] << most_recent_income
        end
        add_data_and_support(key: key, data: data)
        # Then store all incomes for averaging
        key = "all_#{key}".to_sym
        @data.merge!(key => all_incomes)
      end
    end

    def income_most_recent_breakdowns_by_project
      columns = {
        project_id: p_t[:id].to_sql,
        income: ib_t[:TotalMonthlyIncome].to_sql,
        information_date: ib_t[:InformationDate].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        income_most_recent_breakdowns_by_project: :report_scope,
        comparison_income_most_recent_breakdowns_by_project: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = {}
        all_incomes = {}
        send(r_scope).joins(enrollment: :income_benefits).
          distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          [row[:project_id], row[:client_id]]
        end.each do |(project_id, client_id), incomes|
          row = incomes.sort_by{|row| row[:information_date]}.last
          GrdaWarehouse::Hud::IncomeBenefit.income_ranges.each do |income_key, income_bucket|
            data_key = "#{row[:project_id]}__#{income_key}"
            data[data_key] ||= []
            data[data_key] << row if income_bucket[:range].include?(row[:income])
          end
          all_incomes[project_id] ||= []
          most_recent_income = incomes.sort_by{|row| row[:information_date]}.last[:income] || 0
          all_incomes[project_id] << most_recent_income
        end
        add_data_and_support(key: key, data: data)
        # Then store all incomes for averaging
        key = "all_#{key}".to_sym
        @data.merge!(key => all_incomes)
      end
    end

    def income_at_entry_breakdowns_by_project_type
      columns = {
        project_type: :project_type,
        income: ib_t[:TotalMonthlyIncome].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        income_at_entry_breakdowns_by_project_type: :report_scope,
        comparison_income_at_entry_breakdowns_by_project_type: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = {}
        send(r_scope).joins(enrollment: :income_benefits_at_entry).
          distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.each do |row|
          GrdaWarehouse::Hud::IncomeBenefit.income_ranges.each do |income_key, income_bucket|
            data_key = "#{::HUD.project_type_brief(row[:project_type])}__#{income_key}"
            data[data_key] ||= []
            data[data_key] << row if income_bucket[:range].include?(row[:income])
          end
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def income_at_entry_breakdowns_by_project
      columns = {
        project_id: p_t[:id].to_sql,
        income: ib_t[:TotalMonthlyIncome].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        income_at_entry_breakdowns_by_project: :report_scope,
        comparison_income_at_entry_breakdowns_by_project: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = {}
        send(r_scope).joins(enrollment: :income_benefits_at_entry).
          distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.each do |row|
          GrdaWarehouse::Hud::IncomeBenefit.income_ranges.each do |income_key, income_bucket|
            data_key = "#{row[:project_id]}__#{income_key}"
            data[data_key] ||= []
            data[data_key] << row if income_bucket[:range].include?(row[:income])
          end
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def living_situation_breakdowns_by_project_type
      columns = {
        project_type: :project_type,
        living_situation: e_t[:LivingSituation].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        living_situation_breakdowns_by_project_type: :report_scope,
        comparison_living_situation_breakdowns_by_project_type: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = send(r_scope).joins(:enrollment).
          distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          "#{::HUD.project_type_brief(row[:project_type])}__#{::HUD.living_situation(row[:living_situation])}"
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def living_situation_breakdowns_by_project
      columns = {
        project_id: p_t[:id].to_sql,
        living_situation: e_t[:LivingSituation].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        living_situation_breakdowns_by_project: :report_scope,
        comparison_living_situation_breakdowns_by_project: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = send(r_scope).joins(:enrollment).
          distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          "#{row[:project_id]}__#{::HUD.living_situation(row[:living_situation])}"
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def length_of_stay_breakdowns_by_project_type
      columns = {
        project_type: :project_type,
        date: shs_t[:date].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        length_of_stay_breakdowns_by_project_type: :report_scope,
        comparison_length_of_stay_breakdowns_by_project_type: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = {}
        lengths_of_stay = {}
        send(r_scope).joins(:service_history_services).
          distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          [row[:project_type], row[:client_id]]
        end.each do |(project_type, client_id), days|
          row = days.first
          GrdaWarehouse::Hud::Enrollment.lengths_of_stay.each do |stay_key, range|
            data_key = "#{::HUD.project_type_brief(row[:project_type])}__#{stay_key}"
            data[data_key] ||= []
            data[data_key] << row if range.include?(days.count)
          end
          lengths_of_stay[project_type] ||= []
          lengths_of_stay[project_type] << days.count
        end
        add_data_and_support(key: key, data: data)
        # Then store all lengths of stay for averaging
        key = "all_#{key}".to_sym
        @data.merge!(key => lengths_of_stay)

      end


    end

    def length_of_stay_breakdowns_by_project
      columns = {
        project_id: p_t[:id].to_sql,
        date: shs_t[:date].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        length_of_stay_breakdowns_by_project: :report_scope,
        comparison_length_of_stay_breakdowns_by_project: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = {}
        lengths_of_stay = {}
        send(r_scope).joins(:service_history_services).
          distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          [row[:project_id], row[:client_id]]
        end.each do |(project_id, client_id), days|
          row = days.first
          GrdaWarehouse::Hud::Enrollment.lengths_of_stay.each do |stay_key, range|
            data_key = "#{row[:project_id]}__#{stay_key}"
            data[data_key] ||= []
            data[data_key] << row if range.include?(days.count)
          end
          lengths_of_stay[project_id] ||= []
          lengths_of_stay[project_id] << days.count
        end
        add_data_and_support(key: key, data: data)

        # Then store all lengths of stay for averaging
        key = "all_#{key}".to_sym
        @data.merge!(key => lengths_of_stay)
      end
    end

    def age_breakdowns_by_project_type
      columns = {
        project_type: :project_type,
        dob: c_t[:DOB].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        age_breakdowns_by_project_type: :report_scope,
        comparison_age_breakdowns_by_project_type: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = {}
        send(r_scope).distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.each do |row|
          GrdaWarehouse::Hud::Client.extended_age_groups.each do |age_key, age_bucket|
            label = age_bucket[:name].parameterize.underscore
            data_key = "#{::HUD.project_type_brief(row[:project_type])}__#{label}"
            data[data_key] ||= []
            age = GrdaWarehouse::Hud::Client.age(date: Date.current, dob: row[:dob])
            data[data_key] << row if age_bucket[:range].include?(age)
          end
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def age_breakdowns_by_project
      columns = {
        project_id: p_t[:id].to_sql,
        dob: c_t[:DOB].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        age_breakdowns_by_project: :report_scope,
        comparison_age_breakdowns_by_project: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = {}
        send(r_scope).distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.each do |row|
          GrdaWarehouse::Hud::Client.extended_age_groups.each do |age_key, age_bucket|
            label = age_bucket[:name].parameterize.underscore
            data_key = "#{row[:project_id]}__#{label}"
            data[data_key] ||= []
            age = GrdaWarehouse::Hud::Client.age(date: Date.current, dob: row[:dob])
            data[data_key] << row if age_bucket[:range].include?(age)
          end
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def race_breakdowns_by_project_type
      columns = {
        project_type: :project_type,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      ::HUD.races.each do |column, key|
        columns[key.parameterize.underscore] = c_t[column.to_sym].to_sql
      end
      groups = {
        race_breakdowns_by_project_type: :report_scope,
        comparison_race_breakdowns_by_project_type: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = {}
        send(r_scope).distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.each do |row|
          ::HUD.races.each do |column, label|
            race_label = label.parameterize.underscore
            data_key = "#{::HUD.project_type_brief(row[:project_type])}__#{race_label}"
            data[data_key] ||= []
            data[data_key] << row if row[race_label] == 1
          end
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def race_breakdowns_by_project
      columns = {
        project_id: p_t[:id].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      ::HUD.races.each do |column, key|
        columns[key.parameterize.underscore] = c_t[column.to_sym].to_sql
      end
      groups = {
        race_breakdowns_by_project: :report_scope,
        comparison_race_breakdowns_by_project: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = {}
        send(r_scope).distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.each do |row|
          ::HUD.races.each do |column, label|
            race_label = label.parameterize.underscore
            data_key = "#{row[:project_id]}__#{race_label}"
            data[data_key] ||= []
            data[data_key] << row if row[race_label] == 1
          end
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def ethnicity_breakdowns_by_project_type
      columns = {
        project_type: :project_type,
        ethnicity: c_t[:Ethnicity].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        ethnicity_breakdowns_by_project_type: :report_scope,
        comparison_ethnicity_breakdowns_by_project_type: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = send(r_scope).distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          "#{::HUD.project_type_brief(row[:project_type])}__#{::HUD.ethnicity(row[:ethnicity])}"
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def ethnicity_breakdowns_by_project
      columns = {
        project_id: p_t[:id].to_sql,
        ethnicity: c_t[:Ethnicity].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        ethnicity_breakdowns_by_project: :report_scope,
        comparison_ethnicity_breakdowns_by_project: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = send(r_scope).distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          "#{row[:project_id]}__#{::HUD.ethnicity(row[:ethnicity])}"
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def veteran_breakdowns_by_project_type
      columns = {
        project_type: :project_type,
        veteran: c_t[:VeteranStatus].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        veteran_breakdowns_by_project_type: :report_scope,
        comparison_veteran_breakdowns_by_project_type: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = send(r_scope).distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          "#{::HUD.project_type_brief(row[:project_type])}__#{::HUD.veteran_status(row[:veteran])}"
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def veteran_breakdowns_by_project
      columns = {
        project_id: p_t[:id].to_sql,
        veteran: c_t[:VeteranStatus].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        veteran_breakdowns_by_project: :report_scope,
        comparison_veteran_breakdowns_by_project: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = send(r_scope).distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          "#{row[:project_id]}__#{::HUD.veteran_status(row[:veteran])}"
        end
        add_data_and_support(key: key, data: data)
      end
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
        data = send(r_scope).distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          "#{::HUD.project_type_brief(row[:project_type])}__#{::HUD.gender(row[:gender])}"
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def gender_breakdowns_by_project
      columns = {
        project_id: p_t[:id].to_sql,
        gender: c_t[:Gender].to_sql,
        client_id: :client_id,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
      }
      groups = {
        gender_breakdowns_by_project: :report_scope,
        comparison_gender_breakdowns_by_project: :comparison_scope,
      }
      groups.each do |key, r_scope|
        data = send(r_scope).distinct.pluck(*columns.values).map do |row|
          Hash[columns.keys.zip(row)]
        end.group_by do |row|
          "#{row[:project_id]}__#{::HUD.gender(row[:gender])}"
        end
        add_data_and_support(key: key, data: data)
      end
    end

    def add_data_and_support key:, data:
      counts = data.map do |k, group|
        [k, group.size]
      end.to_h
      support = {
        title: key.to_s.titleize,
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

    def enrollment_scope
      @enrollment_scope ||= enrollment_source.entry.send(@sub_population).
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
      self.support = @support = {}
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
      self.data = @data
      self.finished_at = Time.now
      save!
      begin
        # Sometimes the supporting data is too big, this should fail gracefully such that the report appears complete, and just doesn't have the support
        self.support = @support
      rescue
      end
      save!
    end

    def set_token
      self.token = SecureRandom.urlsafe_base64
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
