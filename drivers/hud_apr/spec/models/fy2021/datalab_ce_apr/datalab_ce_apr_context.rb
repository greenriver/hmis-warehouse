###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'datalab ce apr context', shared_context: :metadata do
  def ce_and_es_filter
    project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['DataLab - Coordinated Entry', 'DataLab - ES-EE ESG II (with CE elements)']).pluck(:id)
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: project_ids))
  end

  def ce_only_filter
    project_ids = GrdaWarehouse::Hud::Project.where(ProjectName: ['DataLab - Coordinated Entry']).pluck(:id)
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: project_ids))
  end

  def run(filter)
    generator = HudApr::Generators::CeApr::Fy2021::Generator
    generator.new(::HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: generator.questions.keys)).run!(email: false)
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab ce apr context', include_shared: true
end
