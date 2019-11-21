###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Describes patient enrollments and contains PHI
# Control: PHI attributes documented

require "stupidedi"
module Health
  class Enrollment < HealthBase

    phi_attr :content, Phi::Bulk # contains EDI serialized PHI

    mount_uploader :file, EnrollmentFileUploader
    validates :file, antivirus: true

    belongs_to :user

    def enrollments
      transactions.select{ |transaction| self.class.maintenance_type(transaction) == '021'}
    end

    def disenrollments
      transactions.select{ |transaction| self.class.maintenance_type(transaction) == '024'}
    end

    def self.subscriber_id(transaction)
      transaction.select{|h| h.keys.include? :REF}.
        map{|h| h[:REF]}.each do |ref|
          if ref.detect{|h| h.keys.include? :E128}[:E128][:value][:raw] == '0F'
            return ref.detect{|h| h.keys.include? :E127}[:E127][:value][:raw]
          end
      end
    end

    def self.first_name(transaction)
      NM1(transaction).detect{|h| h.keys.include? :E1036}[:E1036][:value][:raw]
    end

    def self.last_name(transaction)
      NM1(transaction).detect{|h| h.keys.include? :E1035}[:E1035][:value][:raw]
    end

    def self.DOB(transaction)
      Date.parse(
        member(transaction).
        detect{|h| h.keys.include? :DMG}[:DMG].
        detect{|h| h.keys.include? :E1251}[:E1251][:value][:raw]
      )
    end

    def self.SSN(transaction)
      NM1(transaction).detect{|h| h.keys.include? :E67}[:E67][:value][:raw]
    end

    def self.enrollment_date(transaction)
      transaction.select{|h| h.keys.include? :DTP}.
        map{|h| h[:DTP]}.each do |dtp|
          if dtp.detect{|h| h.keys.include? :E374}[:E374][:value][:raw] == '356'
            return Date.parse(dtp.detect{|h| h.keys.include? :E1251}[:E1251][:value][:raw])
          end
      end
    end

    def self.disenrollment_date(transaction)
      transaction.select{|h| h.keys.include? :DTP}.
        map{|h| h[:DTP]}.each do |dtp|
        if dtp.detect{|h| h.keys.include? :E374}[:E374][:value][:raw] == '357'
          return Date.parse(dtp.detect{|h| h.keys.include? :E1251}[:E1251][:value][:raw])
        end
      end
    end

    def self.aco_pid_sl(transaction)
      transaction.select{|h| h.keys.include? :REF}.
        map{|h| h[:REF]}.each do |ref|
        type = ref.detect{|h| h.keys.include? :E128}[:E128][:value][:raw]
        if type == 'PID'
          return ref.detect{|h| h.keys.include? :E127}[:E127][:value][:raw]
        end
      end
      return nil
    end

    def self.maintenance_type(transaction)
      INS(transaction).detect{|h| h.keys.include? :E875}[:E875][:value][:raw]
    end

    def self.INS(transaction)
      transaction.detect{|h| h.keys.include? :INS}[:INS]
    end

    def self.NM1(transaction)
      member(transaction).
      detect{|h| h.keys.include? :NM1}[:NM1]
    end

    def self.member(transaction)
      transaction.detect{|h| h.keys.include? "2100A - MEMBER"}["2100A - MEMBER"]
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