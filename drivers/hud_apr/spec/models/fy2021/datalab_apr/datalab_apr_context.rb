###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'datalab apr context', shared_context: :metadata do
  def project_type_filter(project_type)
    project_ids = GrdaWarehouse::Hud::Project.where(ProjectType: project_type).pluck(:id)
    project_ids_filter(project_ids)
  end

  def project_ids_filter(project_ids)
    ::Filters::HudFilterBase.new(shared_filter_spec.merge(project_ids: Array.wrap(project_ids)))
  end

  def rrh_1_filter
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: '808').id
    project_ids_filter(project_id)
  end

  def run(filter)
    generator = HudApr::Generators::Apr::Fy2021::Generator
    generator.new(::HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: generator.questions.keys)).run!(email: false)
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab apr context', include_shared: true
end
