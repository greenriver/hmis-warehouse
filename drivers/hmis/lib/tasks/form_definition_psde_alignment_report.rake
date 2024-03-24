# frozen_string_literal: true

# rails driver:hmis:form_definition_psde_alignment_report[2024-01-01]
desc 'CSV report for projects with PSDEs that are represented in the form definition due to filtering'
task :form_definition_psde_alignment_report, [:start_date] => :environment do |_task, args|
  task_class = Class.new do
    attr_accessor :start_date
    def initialize(start_date:)
      self.start_date = start_date
    end

    def perform
      # use warehouse project model which has direct associations to income_benefits, disabilities, etc
      projects = GrdaWarehouse::Hud::Project.where(data_source: data_source)
      rows = projects.map do |project|
        project_row(project)
      end

      puts print_csv(rows)
    end

    protected

    def print_csv(records)
      CSV.generate do |csv|
        headers = records.first.keys
        csv << headers
        records.each do |record|
          csv << record.values_at(*headers)
        end
      end
    end

    def project_row(project)
      hmis_project = Hmis::Hud::Project.find(project.id)
      intake_fd = Hmis::Form::Definition.find_definition_for_role(:INTAKE, project: hmis_project)
      item_tree = filter_form_definition_items(project: hmis_project, form_definition: intake_fd)
      link_ids = collect_link_ids(item_tree).to_set
      {
        project_id: project.id,

        income_and_sources_link_id: 'income-and-sources'.in?(link_ids),
        non_cash_benefits_link_id: 'non-cash-benefits'.in?(link_ids),
        health_insurance_link_id: 'health-insurance'.in?(link_ids),
        disability_table_link_id: 'disability-table'.in?(link_ids),
        disability_table_r4_link_id: 'disability-table-r4'.in?(link_ids),
        health_and_dvs_link_id: '4.11'.in?(link_ids),

        income_benefits_count: filter_scope(project.income_benefits).count,
        disability_count: filter_scope(project.disabilities.where.not(DisabilityType: [nil, 8])).count,
        disability_r4_count: filter_scope(project.disabilities.where(DisabilityType: 8)).count,
        health_and_dvs_count: filter_scope(project.health_and_dvs).count,
      }
    end

    def filter_scope(scope)
      start_date ? scope.where(InformationDate: start_date..) : scope
    end

    def filter_form_definition_items(project:, form_definition:)
      project_funders = project.funders.to_a.filter { |f| f.active_on?(today) }

      Hmis::Form::DefinitionItemFilter.perform(
        definition: form_definition.definition,
        project: project,
        project_funders: project_funders,
        active_date: today,
      )
    end

    def collect_link_ids(root)
      link_ids = []
      walk = ->(item) {
        item['item']&.each do |child|
          walk.call(child)
        end
        link_ids << item['link_id']
      }
      walk.call(root)
      link_ids.compact
    end

    def today
      @today ||= Date.current
    end

    def data_source
      @data_source ||= GrdaWarehouse::DataSource.hmis.first!
    end
  end

  task_class.new(start_date: args.start_date ? Date.parse(args.start_date) : nil).perform
end
