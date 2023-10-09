###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'datalab caper context', shared_context: :metadata do
  def project_type_filter(project_type)
    project_ids = GrdaWarehouse::Hud::Project.where(ProjectType: project_type).pluck(:id)
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: project_ids))
  end

  def project_ids_filter(project_ids)
    ::Filters::HudFilterBase.new(shared_filter_spec.merge(project_ids: Array.wrap(project_ids)))
  end

  def run(filter)
    generator = HudApr::Generators::Caper::Fy2021::Generator
    generator.new(::HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: generator.questions.keys)).run!(email: false)
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab caper context', include_shared: true
end
