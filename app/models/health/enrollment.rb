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

    def enrollments
      transactions.select{ |transaction| maintenance_type(transaction) == '021'}
    end

    def disenrollments
      transactions.select{ |transaction| maintenance_type(transaction) == '024'}
    end

    def subscriber_id(transaction)
      transaction.select{|h| h.keys.include? :REF}.
        map{|h| h[:REF]}.each do |ref|
          if ref.detect{|h| h.keys.include? :E128}[:E128][:value][:raw] == '0F'
            return ref.detect{|h| h.keys.include? :E127}[:E127][:value][:raw]
          end
      end
    end

    def maintenance_type(transaction)
      INS(transaction).detect{|h| h.keys.include? :E875}[:E875][:value][:raw]
    end

    def INS(transaction)
      transaction.detect{|h| h.keys.include? :INS}[:INS]
    end

    def transactions
      return [] unless as_json.present?
      @json_transactions ||= as_json[:interchanges].
        detect{|h| h.keys.include? :functional_groups}[:functional_groups].
        detect{|h| h.keys.include? :transactions}[:transactions].
        detect{|h| h.keys.include? "2 - Detail"}['2 - Detail'].
        select{|h| h.keys.include? "2000 - MEMBER LEVEL DETAIL"}.
        map{|h| h["2000 - MEMBER LEVEL DETAIL"]}
    end

    def as_json
      return {} unless content.present?
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