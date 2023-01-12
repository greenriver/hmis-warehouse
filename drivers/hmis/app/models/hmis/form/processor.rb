###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::Processor < ::GrdaWarehouseBase
  self.table_name = :hmis_assessment_processors

  belongs_to :assessment_detail

  def run!
    return unless assessment_detail.hud_values.present?

    assessment_detail.hud_values.each do |key, value|
      # Don't use greedy matching so that the container is up to the first dot, and the rest is the field
      container, field = /(.*?)\.(.*)/.match(key)[1..2]

      container_processor(container)&.process(field, value)
    end
  end

  private def container_processor(container)
    container = container.to_sym
    return unless container.in?(valid_containers.keys)

    @container_processors ||= {}
    @container_processors[container] ||= valid_containers[container].new(self)
  end

  private def valid_containers
    @valid_containers ||= {
      DisabilityGroup: Hmis::Hud::Processors::DisabilityGroupProcessor,
      Enrollment: Hmis::Hud::Processors::EnrollmentProcessor,
      HealthAndDv: Hmis::Hud::Processors::HealthAndDvProcessor,
      IncomeBenefit: Hmis::Hud::Processors::IncomeBenefitProcessor,
    }.freeze
  end
end
