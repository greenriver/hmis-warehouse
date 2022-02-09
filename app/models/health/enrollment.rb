###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Describes patient enrollments and contains PHI
# Control: PHI attributes documented

require 'stupidedi'
module Health
  class Enrollment < HealthBase
    phi_attr :content, Phi::Bulk, 'Description of content of enrollment file' # contains EDI serialized PHI

    mount_uploader :file, EnrollmentFileUploader

    belongs_to :user, optional: true

    ENROLLMENT = '021'.freeze
    DISENROLLMENT = '024'.freeze
    CHANGE = '001'.freeze
    AUDIT = '030'.freeze

    def self.maintenance_code_to_string(code)
      @maintenance_types ||= {
        ENROLLMENT => 'Enrollment',
        DISENROLLMENT => 'Disenrollment',
        CHANGE => 'Change',
        AUDIT => 'Audit',
      }.freeze
      @maintenance_types[code]
    end

    def self.maintenance_type_name(transaction)
      maintenance_code_to_string(maintenance_type(transaction))
    end

    def self.describe(transaction)
      "#{maintenance_type_name(transaction)}: " +
        "#{first_name(transaction)} #{last_name(transaction)}" +
        " (#{subscriber_id(transaction)})"
    end

    def enrollments
      transactions.select { |transaction| self.class.maintenance_type(transaction) == '021' }
    end

    def disenrollments
      transactions.select { |transaction| self.class.maintenance_type(transaction) == '024' }
    end

    def changes
      transactions.select { |transaction| self.class.maintenance_type(transaction) == '001' }
    end

    def audits
      audits = transactions.select { |transaction| self.class.maintenance_type(transaction) == '030' }
      # Order the audits so that if a disenrollment and subsequent enrollment both appear, the disenrollment is
      # appears first
      audits.sort_by { |t| self.class.disenrollment_date(t) || self.class.enrollment_date(t) }
    end

    def self.subscriber_id(transaction)
      transaction.select { |h| h.keys.include? :REF }.
        map { |h| h[:REF] }.each do |ref|
        return ref.detect { |h| h.keys.include? :E127 }[:E127][:value][:raw] if ref.detect { |h| h.keys.include? :E128 }[:E128][:value][:raw] == '0F'
      end
    end

    def self.first_name(transaction)
      NM1(transaction).detect { |h| h.keys.include? :E1036 }[:E1036][:value][:raw]
    end

    def self.last_name(transaction)
      NM1(transaction).detect { |h| h.keys.include? :E1035 }[:E1035][:value][:raw]
    end

    def self.middle_initial(transaction)
      NM1(transaction).detect { |h| h.keys.include? :E1037 }[:E1037][:value][:raw]
    end

    def self.name_suffix(transaction)
      NM1(transaction).detect { |h| h.keys.include? :E1039 }[:E1039][:value][:raw]
    end

    def self.DOB(transaction) # rubocop:disable Naming/MethodName
      Date.parse(
        member(transaction).
        detect { |h| h.keys.include? :DMG }[:DMG].
        detect { |h| h.keys.include? :E1251 }[:E1251][:value][:raw],
      )
    end

    def self.gender(transaction)
      member(transaction).
        detect { |h| h.keys.include? :DMG }[:DMG].
        detect { |h| h.keys.include? :E1068 }[:E1068][:value][:raw]
    end

    def self.SSN(transaction) # rubocop:disable Naming/MethodName
      NM1(transaction).detect { |h| h.keys.include? :E67 }[:E67][:value][:raw]
    end

    def self.enrollment_date(transaction)
      transaction.select { |h| h.keys.include? :DTP }.
        map { |h| h[:DTP] }.each do |dtp|
        return Date.parse(dtp.detect { |h| h.keys.include? :E1251 }[:E1251][:value][:raw]) if dtp.detect { |h| h.keys.include? :E374 }[:E374][:value][:raw] == '356'
      end
    end

    def self.disenrollment_date(transaction)
      transaction.select { |h| h.keys.include? :DTP }.
        map { |h| h[:DTP] }.each do |dtp|
        next unless dtp.detect { |h| h.keys.include? :E374 }[:E374][:value][:raw] == '357'

        date = Date.parse(dtp.detect { |h| h.keys.include? :E1251 }[:E1251][:value][:raw])
        # MassHealth will send a date far in the future if there is no disenrollment date
        if date < Date.current + 1.year # rubocop:disable Style/GuardClause
          return date
        else
          return nil
        end
      end
    end

    def self.disenrollment_reason_code(transaction)
      transaction.select { |h| h.keys.include? :REF }.
        map { |h| h[:REF] }.each do |ref|
        if ref.detect { |h| h.keys.include? :E128 }[:E128][:value][:raw] == 'ZZ'
          return ref.detect { |h| h.keys.include? :E127 }[:E127][:value][:raw].first(2) # Reason code is first 2 characters
        end
      end
    end

    def self.aco_pid_sl(transaction)
      transaction.select { |h| h.keys.include? :REF }.
        map { |h| h[:REF] }.each do |ref|
        type = ref.detect { |h| h.keys.include? :E128 }[:E128][:value][:raw]
        return ref.detect { |h| h.keys.include? :E127 }[:E127][:value][:raw] if type == 'PID'
      end
      return nil
    end

    def self.maintenance_type(transaction)
      INS(transaction).detect { |h| h.keys.include? :E875 }[:E875][:value][:raw]
    end

    def self.INS(transaction) # rubocop:disable Naming/MethodName
      transaction.detect { |h| h.keys.include? :INS }[:INS]
    end

    def self.NM1(transaction) # rubocop:disable Naming/MethodName
      member(transaction).
        detect { |h| h.keys.include? :NM1 }[:NM1]
    end

    def self.member(transaction)
      transaction.detect { |h| h.keys.include? '2100A - MEMBER' }['2100A - MEMBER']
    end

    def transactions
      return [] unless as_json.present?

      @transactions ||= as_json[:interchanges].
        detect { |h| h.keys.include? :functional_groups }[:functional_groups].
        detect { |h| h.keys.include? :transactions }[:transactions].
        detect { |h| h.keys.include? '2 - Detail' }['2 - Detail'].
        select { |h| h.keys.include? '2000 - MEMBER LEVEL DETAIL' }.
        map { |h| h['2000 - MEMBER LEVEL DETAIL'] }
    end

    def file_date
      return nil unless as_json.present?

      Date.parse(as_json[:interchanges].
        detect { |h| h.keys.include? :ISA }[:ISA].
        detect { |h| h.keys.include? :I08 }[:I08][:value][:raw])
    end

    def receiver_id
      return nil unless as_json.present?

      as_json[:interchanges].
        detect { |h| h.keys.include? :ISA }[:ISA].
        detect { |h| h.keys.include? :I07 }[:I07][:value][:raw]
    end

    def as_json
      return {} unless content.present?

      @as_json ||= begin
        json = {}
        parsed_834 = parse_834
        return {} unless parsed_834.present?

        parsed_834.zipper.tap { |z| Stupidedi::Writer::Json.new(z.root.node).write(json) }
        json
      end
    end

    def parse_834
      return nil unless content.present?

      config = Stupidedi::Config.hipaa
      parser = Stupidedi::Parser::StateMachine.build(config)
      parsed, result = parser.read(Stupidedi::Reader.build(content))
      result.explain { |reason| raise reason + " at #{result.position.inspect}" } if result.fatal?
      return parsed
    end
  end
end
