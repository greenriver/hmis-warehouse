###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Describes patient enrollments and contains PHI
# Control: PHI attributes documented

module Health
  class Enrollment < HealthBase

    phi_attr :content, Phi::Bulk # contains EDI serialized PHI

    mount_uploader :file, EnrollmentFileUploader

    belongs_to :user

    def as_json
      return {} unless response.present?
      @json ||= begin
        json = {}
        parsed_834 = parse_834
        return {} unless parsed_834.present?
        parsed_834.zipper.tap{ |z| Stupidedi::Writer::Json.new(z.root.node).write(json) }
        json
      end
    end

    def parse_834
      return nil unless content.present?
      config = Stupidedi::Config.hipaa
      parser = Stupidedi::Parser::StateMachine.build(config)
      parsed, result = parser.read(Stupidedi::Reader.build(content))
      if result.fatal?
        result.explain{|reason| raise reason + " at #{result.position.inspect}" }
      end
      return parsed
    end
  end
end