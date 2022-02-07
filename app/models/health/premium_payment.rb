###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Attached content contains EDI serialized PHI
# Control: PHI attributes documented

require "stupidedi"
module Health
  class PremiumPayment < HealthBase
    acts_as_paranoid

    phi_attr :id, Phi::SmallPopulation
    phi_attr :content, Phi::Bulk # contains EDI serialized PHI

    mount_uploader :file, PremiumPaymentFileUploader

    belongs_to :user, optional: true

    scope :unprocessed, -> do
      where(started_at: nil)
    end

    scope :complete, -> do
      where.not(completed_at: nil)
    end

    def process!
      update(started_at: Time.now, completed_at: nil)
      update(converted_content: {summary: summary, details: details}, completed_at: Time.now)
    end

    def status
      if completed?
        'Processed'
      elsif started?
        'Processing'
      else
        'Queued for processing'
      end
    end

    def completed?
      completed_at.present?
    end

    def started?
      started_at.present?
    end

    def summary

      @summary = {}
      gs = as_json[:interchanges].detect{|h| h.keys.include? :functional_groups}[:functional_groups].first[:GS].map(&:values).flatten
      pid_sl = gs.detect{|h| h[:name] == "Application Receiver's Code"}[:value][:raw]
      @summary.merge!(Health::AccountableCareOrganization.split_pid_sl(pid_sl))
      @summary[:cp_name] = cp_name_for(@summary[:pid], @summary[:sl])

      headers = as_json[:interchanges].detect{|h| h.keys.include? :functional_groups}[:functional_groups].
        detect{|h| h.keys.include? :transactions}[:transactions].first.values.flatten

      bpr = headers.detect{|h| h.keys.include? :BPR}[:BPR].map(&:values).flatten

      total_amount_paid = bpr[1][:value][:raw]&.to_f
      @summary[:total_amount_paid] = total_amount_paid

      dtm = headers.detect{|h| h.keys.include? :DTM}[:DTM].map(&:values).flatten
      date_range = dtm[5][:value][:raw].split('-').map(&:to_date)
      @summary[:start_date] = date_range.first
      @summary[:end_date] = date_range.last

      @summary[:member_count] = patient_medicaid_ids.count

      # We're leaving this here for future development, but using the json writer is more efficient currently
      # NOTE: https://github.com/irobayna/stupidedi/issues/13
      # parse_820.first.flatmap{|m| m.find(:GS) }.tap do |gs|
      #   el(gs, 3) do |e|
      #     @summary[:pid] = e[0, e.length - 1]
      #     @summary[:sl] = e[-1]
      #   end
      #   gs.iterate(:ST) do |st|
      #     st.iterate(:BPR) do |bpr|
      #       el(bpr, 2) do |e|
      #         @summary[:total_amount_paid] = e.to_i
      #       end
      #       bpr.find(:DTM).tap do |dtm|
      #         el(dtm, 6) do |e|
      #           @summary[:date_range] = (e.to_date..e.to_date)
      #         end
      #       end
      #     end
      #   end
      # end
      return @summary
    end

    def as_json
      @json ||= begin
        json = {}
        parse_820.zipper.tap{ |z| Stupidedi::Writer::Json.new(z.root.node).write(json) }
        json
      end
    end

    def details
      @details ||= begin
        details = []
        data = as_json[:interchanges].detect{|h| h.keys.include? :functional_groups}[:functional_groups].
          detect{|h| h.keys.include? :transactions}[:transactions].select{|h| h.keys.include? "2 - Detail"}
        data.each do |h|
          patient = h.values.first

          ent = patient.detect{|h| h.keys.include? :ENT}&.values&.flatten&.map(&:values)&.flatten
          nm1 = patient.detect{|h| h.keys.include? :NM1}&.values&.flatten&.map(&:values)&.flatten
          rmr = patient.detect{|h| h.keys.include? :RMR}&.values&.flatten&.map(&:values)&.flatten
          dtm = patient.detect{|h| h.keys.include? :DTM}&.values&.flatten&.map(&:values)&.flatten
          adx = patient.detect{|h| h.keys.include? :ADX}&.values&.flatten&.map(&:values)&.flatten

          mass_health_id = ent[3][:value][:raw] rescue nil
          first_name = nm1[3][:value][:raw] rescue nil
          last_name = nm1[2][:value][:raw] rescue nil
          middle_name = nm1[4][:value][:raw] rescue nil
          sender_code = rmr[1][:value][:raw] rescue nil
          premium_payment = rmr[3][:value][:raw] rescue nil
          premium_billed = rmr[4][:value][:raw] rescue nil
          date_time_qualifier = dtm[0][:value][:raw] rescue nil
          date = dtm[1][:value][:raw] rescue nil
          time = dtm[2][:value][:raw] rescue nil
          coverage_period = dtm[5][:value][:raw] rescue nil
          adjustment_amount = adx[0][:value][:raw] rescue nil
          adjustment_reason = adx[1][:value][:raw] rescue nil
          details << [
            mass_health_id,
            first_name,
            middle_name,
            last_name,
            sender_code,
            enrollment_start_date_for(mass_health_id),
            premium_payment,
            premium_billed,
            adjustment_amount,
            adjustment_reason,
            coverage_period,
          ]
        end
        details
      end
    end

    def patient_medicaid_ids
      details.map(&:first).uniq
    end

    def patient_referrals
      @patient_referrals ||= Health::PatientReferral.pluck(*patient_referral_columns).to_h
    end

    def enrollment_start_date_for medicaid_id
      patient_referrals[medicaid_id]
    end

    def patient_referral_columns
      @patient_referral_columns ||= [
        :medicaid_id,
        :enrollment_start_date,
      ]
    end

    def cps
      @cps ||= Health::Cp.all.index_by{|m| [m.pid, m.sl]}
    end

    def cp_name_for pid, sl
      cps[[pid,sl]]&.mmis_enrollment_name
    end

    def detail_headers
      [
        'Mass Health ID',
        'First Name',
        'Last Name',
        'Middle Name',
        'Member CP Assignment Plan',
        'CP Enrollment Start Date',
        'Premium Payment',
        'Billed Premium',
        'Adjustment Amount',
        'Adjustment Reason Code',
        'Coverage Period',
      ]
    end

    def parse_820
      @parse_820 ||= begin
        config = Stupidedi::Config.contrib
        parser = Stupidedi::Parser::StateMachine.build(config)
        # .gsub('~', "~\n")
        parsed, result = parser.read(Stupidedi::Reader.build(content))
        if result.fatal?
          result.explain{|reason| raise reason + " at #{result.position.inspect}" }
        end
        parsed
      end
    end


    # Helper function: fetch an element from the current segment
    def el(m, *ns, &block)
      if Stupidedi::Either === m
        m.tap{|m| el(m, *ns, &block) }
      else
        yield(*ns.map{|n| m.elementn(n).map(&:value).fetch })
      end
    end

  end
end
