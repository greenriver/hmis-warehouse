###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Describes an insurance eligibility response and contains PHI
# Control: PHI attributes documented

require 'stupidedi'
module Health
  class EligibilityResponse < HealthBase
    acts_as_paranoid

    phi_attr :response, Phi::Bulk, 'Description of eligibility inquiry response' # contains EDI serialized PHI

    mount_uploader :file, EligibilityResponseFileUploader

    belongs_to :eligibility_inquiry, class_name: 'Health::EligibilityInquiry', optional: true
    belongs_to :user, optional: true

    def summary_headers
      [
        'Medicaid ID',
        'Eligible',
        'Managed Care',
        'ACO',
        'Coverage Types',
        'Rejection Code',
        'Copay',
        'Copay Total',
        'Copay Msg',
      ]
    end

    def summary_rows
      subscribers.map do |subscriber|
        benefit_names = EBNM1(subscriber)
        coverages = EB(subscriber).map { |(code, coverage)| "#{code}/#{coverage}" }.join(', ')
        copays = copays(subscriber)
        messages = MSG(subscriber)
        [
          TRN(subscriber),
          eligible(subscriber),
          managed_care(subscriber),
          benefit_names['MC'] || benefit_names['L'],
          coverages,
          AAA(subscriber),
          copays['B'],
          copays['J'],
          messages['366'] || messages['246'],
        ]
      end
    end

    def subscriber_ids_with_errors
      @subscriber_ids_with_errors ||= subscribers.select { |s| AAA(s) }.map { |s| TRN(s) }
    end

    def invalid_subscriber_ids
      # 72 = invalid SSN/MemberID
      @invalid_subscriber_ids = subscribers.select { |s| ['72'].include?(AAA(s)) }.map { |s| TRN(s) }
    end

    def subscriber_ids
      @subscriber_ids ||= subscribers.map { |s| TRN(s) } - subscriber_ids_with_errors
    end

    def eligible_ids
      @eligible_ids ||= subscribers.select { |s| eligible(s) }.map { |s| TRN(s) } - subscriber_ids_with_errors
    end

    def managed_care_ids
      @managed_care_ids ||= subscribers.select { |s| managed_care(s) }.map { |s| TRN(s) } - subscriber_ids_with_errors
    end

    def aco_names
      @aco_names ||= begin
        results = {}
        subscribers.select { |s| managed_care(s) }.each do |s|
          names = EBNM1(s)
          name = names['MC'] || names['L']
          results[TRN(s)] = name
        end
        results
      end
    end

    def ineligible_ids
      @ineligible_ids ||= subscribers.reject { |s| eligible(s) }.map { |s| TRN(s) } - subscriber_ids_with_errors
    end

    def eligible_clients
      count = num_eligible
      count || begin
        count = eligible_ids.count
        update(num_eligible: count)
        count
      end
    end

    def ineligible_clients
      count = num_ineligible
      count || begin
        count = ineligible_ids.count
        update(num_ineligible: count)
        count
      end
    end

    def client_errors
      count = num_errors
      count || begin
        count = subscriber_ids_with_errors.count
        update(num_errors: count)
        count
      end
    end

    def TRN(subscriber) # rubocop:disable Naming/MethodName
      subscriber['2000C SUBSCRIBER LEVEL'].
        select { |h| h.keys.include? :TRN }.map { |h| h[:TRN] }.
        each do |trn|
        source = trn.detect { |h| h.keys.include? :E509 }[:E509][:value][:raw]
        return trn.detect { |h| h.keys.include? :E127 }[:E127][:value][:raw] if source == sender.trace_id
      end
      return nil
    end

    def eligible(subscriber)
      ebs = EB(subscriber)
      masshealth = ebs.any? { |eb| eb.first == '1' } || false
      medicare = ebs.any? { |eb| eb.first == 'R' && eb.last.include?('MEDICARE') } || false

      masshealth && !medicare
    end

    def managed_care(subscriber)
      ebs = EB(subscriber)
      managed_care = ebs.any? { |eb| eb.first == 'MC' } || false

      managed_care
    end

    def AAA(subscriber) # rubocop:disable Naming/MethodName
      # Reject reasons can also appear in 2100A (information source) or 2100B (information receiver) which we are ignoring
      sub_name = subscriber['2000C SUBSCRIBER LEVEL'].
        detect { |h| h.keys.include? '2100C SUBSCRIBER NAME' }['2100C SUBSCRIBER NAME']
      errs = sub_name.detect { |h| h.keys.include? :AAA }
      return nil unless errs.present?

      aaa = errs[:AAA]
      valid = aaa.detect { |h| h.keys.include? :E1073 }[:E1073][:value][:raw]
      reason = aaa.detect { |h| h.keys.include? :E901 }[:E901][:value][:raw]
      return reason if valid == 'N'
    end

    def EB(subscriber) # rubocop:disable Naming/MethodName
      codes = []
      text = []
      subscriber['2000C SUBSCRIBER LEVEL'].
        detect { |h| h.keys.include? '2100C SUBSCRIBER NAME' }['2100C SUBSCRIBER NAME'].
        select { |h| h.keys.include? '2110C SUBSCRIBER ELIGIBILITY OR BENEFIT INFORMATION' }.
        each do |info|
          eb = info['2110C SUBSCRIBER ELIGIBILITY OR BENEFIT INFORMATION'].
            detect { |h| h.keys.include? :EB }[:EB]
          codes << eb.detect { |h| h.keys.include? :E1390 }[:E1390][:value][:raw]
          text << eb.detect { |h| h.keys.include? :E1204 }[:E1204][:value][:raw]
        end
      return codes.zip(text)
    end

    def copays(subscriber)
      codes = []
      amounts = []
      subscriber['2000C SUBSCRIBER LEVEL'].
        detect { |h| h.keys.include? '2100C SUBSCRIBER NAME' }['2100C SUBSCRIBER NAME'].
        select { |h| h.keys.include? '2110C SUBSCRIBER ELIGIBILITY OR BENEFIT INFORMATION' }.
        each do |info|
        eb = info['2110C SUBSCRIBER ELIGIBILITY OR BENEFIT INFORMATION'].
          detect { |h| h.keys.include? :EB }[:EB]
        code = eb.detect { |h| h.keys.include? :E1390 }[:E1390][:value][:raw]
        next unless ['B', 'J'].include?(code)

        codes << code
        amounts << eb.detect { |h| h.keys.include? :E782 }[:E782][:value][:raw]
      end
      return codes.zip(amounts).to_h
    end

    def MSG(subscriber) # rubocop:disable Naming/MethodName
      msgs = {}
      subscriber['2000C SUBSCRIBER LEVEL'].
        detect { |h| h.keys.include? '2100C SUBSCRIBER NAME' }['2100C SUBSCRIBER NAME'].
        select { |h| h.keys.include? '2110C SUBSCRIBER ELIGIBILITY OR BENEFIT INFORMATION' }.
        each do |info|
        info['2110C SUBSCRIBER ELIGIBILITY OR BENEFIT INFORMATION'].
          select { |h| h.keys.include? :MSG }.
          each do |msg|
          words = msg[:MSG].detect { |h| h.keys.include? :E933 }[:E933][:value][:raw].split(' ', 2)
          msgs[words[0]] = words[1]
        end
      end
      msgs
    end

    def EBNM1(subscriber) # rubocop:disable Naming/MethodName
      names = {}
      subscriber['2000C SUBSCRIBER LEVEL'].
        detect { |h| h.keys.include? '2100C SUBSCRIBER NAME' }['2100C SUBSCRIBER NAME'].
        select { |h| h.keys.include? '2110C SUBSCRIBER ELIGIBILITY OR BENEFIT INFORMATION' }.
        each do |info|
          eb = info['2110C SUBSCRIBER ELIGIBILITY OR BENEFIT INFORMATION'].
            detect { |h| h.keys.include? :EB }[:EB]
          code = eb.detect { |h| h.keys.include? :E1390 }[:E1390][:value][:raw]
          loop = info['2110C SUBSCRIBER ELIGIBILITY OR BENEFIT INFORMATION'].
            detect { |h| h.keys.include? '2120C LOOP HEADER' }
          next unless loop

          text = loop['2120C LOOP HEADER'].
            detect { |h| h.keys.include? '2120C SUBSCRIBER BENEFIT RELATED ENTITY NAME' }['2120C SUBSCRIBER BENEFIT RELATED ENTITY NAME'].
            detect { |h| h.keys.include? :NM1 }[:NM1].
            detect { |h| h.keys.include? :E1035 }[:E1035][:value][:raw]
          names[code] = text if text
        end
      return names
    end

    def subscribers
      return [] unless as_json.present?

      @subscribers ||= as_json[:interchanges].
        detect { |h| h.keys.include? :functional_groups }[:functional_groups].
        detect { |h| h.keys.include? :transactions }[:transactions].
        select { |h| h.keys.include? '2 - Subscriber Detail' }.
        map { |h| h['2 - Subscriber Detail'] }.flatten
    end

    def sender
      @sender ||= Health::Cp.sender.first
    end

    def as_json
      return {} unless response.present?

      @as_json ||= begin
        json = {}
        parsed_271 = parse_271
        return {} unless parsed_271.present?

        parsed_271.zipper.tap { |z| Stupidedi::Writer::Json.new(z.root.node).write(json) }
        json
      end
    end

    def parse_271
      return nil unless response.present?

      config = Stupidedi::Config.hipaa
      parser = Stupidedi::Parser::StateMachine.build(config)
      parsed, result = parser.read(Stupidedi::Reader.build(response))
      result.explain { |reason| raise reason + " at #{result.position.inspect}" } if result.fatal?
      return parsed
    end
  end
end
