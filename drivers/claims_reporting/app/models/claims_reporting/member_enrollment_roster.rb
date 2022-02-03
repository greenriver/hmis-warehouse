###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClaimsReporting
  class MemberEnrollmentRoster < HealthBase
    phi_patient :member_id

    belongs_to :patient, foreign_key: :member_id, class_name: 'Health::Patient', primary_key: :medicaid_id, optional: true

    belongs_to :member_roster,
               primary_key: 'member_id',
               foreign_key: 'member_id',
               class_name: 'ClaimsReporting::MemberRoster',
               optional: true
    has_many :medical_claims, primary_key: 'member_id', foreign_key: 'member_id', class_name: 'ClaimsReporting::MedicalClaim'

    has_many :engaged_claims, -> do
      h_mer_t = ClaimsReporting::MemberEnrollmentRoster.arel_table
      h_mc_t = ClaimsReporting::MedicalClaim.arel_table
      where(
        h_mer_t[:engagement_date].not_eq(nil).
        and(
          h_mc_t[:service_start_date].gteq(h_mer_t[:engagement_date]).
          and(h_mc_t[:service_start_date].lt(cl(h_mer_t[:span_end_date], Date.current))),
        ),
      )
      # where(['engagement_date is not null and service_start_date between (engagement_date and coalesce(span_end_date, ?))', Date.current])
    end, primary_key: 'member_id', foreign_key: 'member_id', class_name: 'ClaimsReporting::MedicalClaim'

    has_many :pre_engaged_claims, -> do
      h_mer_t = ClaimsReporting::MemberEnrollmentRoster.arel_table
      h_mc_t = ClaimsReporting::MedicalClaim.arel_table
      where(
        # Include claims that occurred before the first enrollment, or within any enrollment before the engagement date
        h_mc_t[:service_start_date].gteq(cl(h_mer_t[:first_claim_date], h_mer_t[:span_start_date])).
        and(h_mc_t[:service_start_date].lt(cl(h_mer_t[:engagement_date], h_mer_t[:span_end_date], Date.current))),
      )
      # where(['service_start_date between (span_start_date and coalesce(engagement_date, span_end_date, ?))', Date.current])
    end, primary_key: 'member_id', foreign_key: 'member_id', class_name: 'ClaimsReporting::MedicalClaim'

    include ClaimsReporting::CsvHelpers

    scope :unprocessed_engagement, -> do
      where(engagement_date: nil).or(
        where(
          arel_table[:enrollment_end_at_engagement_calculation].lt(arel_table[:span_end_date]),
        ),
      )
    end

    scope :enrolled, -> do
      where(member_id: ::Health::PatientReferral.select(:medicaid_id))
    end

    scope :engaged, -> do
      where.not(engagement_date: nil)
    end

    scope :engaged_for, ->(range) do
      where(member_id: enrolled.having(nf('sum', [arel_table[:engaged_days]]).between(range)).
        group(:member_id).select(:member_id))
    end

    def self.conflict_target
      ['member_id', 'span_start_date']
    end

    phi_attr :member_id, Phi::HealthPlan

    phi_attr :span_start_date, Phi::Date
    phi_attr :span_end_date, Phi::Date
    phi_attr :span_mem_days, Phi::SmallPopulation
    phi_attr :cp_enroll_dt, Phi::Date
    phi_attr :cp_disenroll_dt, Phi::Date

    phi_attr :service_area, Phi::SmallPopulation
    phi_attr :aco_pidsl, Phi::SmallPopulation
    phi_attr :aco_name, Phi::SmallPopulation
    phi_attr :pcc_pidsl, Phi::SmallPopulation
    phi_attr :pcc_name, Phi::SmallPopulation
    phi_attr :pcc_npi, Phi::SmallPopulation
    phi_attr :pcc_taxid, Phi::SmallPopulation
    phi_attr :mco_pidsl, Phi::SmallPopulation
    phi_attr :mco_name, Phi::SmallPopulation
    phi_attr :enroll_type, Phi::SmallPopulation # unpopulated?
    phi_attr :enroll_stop_reason, Phi::SmallPopulation # unpopulated?
    phi_attr :rating_category_char_cd, Phi::SmallPopulation
    phi_attr :ind_dds, Phi::SmallPopulation
    phi_attr :ind_dmh, Phi::SmallPopulation
    phi_attr :ind_dta, Phi::SmallPopulation
    phi_attr :ind_dss, Phi::SmallPopulation
    phi_attr :cde_hcb_waiver, Phi::SmallPopulation
    phi_attr :cde_waiver_category, Phi::SmallPopulation
    phi_attr :cp_prov_type, Phi::SmallPopulation
    phi_attr :cp_plan_type, Phi::SmallPopulation
    phi_attr :cp_pidsl, Phi::SmallPopulation
    phi_attr :cp_prov_name, Phi::SmallPopulation
    phi_attr :cp_stop_rsn, Phi::SmallPopulation # mostly unpopulated
    phi_attr :cp_start_rsn, Phi::SmallPopulation # mostly unpopulated
    phi_attr :cp_stop_rsn, Phi::SmallPopulation # mostly unpopulated
    phi_attr :ind_medicare_a, Phi::SmallPopulation
    phi_attr :ind_medicare_b, Phi::SmallPopulation
    phi_attr :tpl_coverage_cat, Phi::SmallPopulation

    # pidsl: Provider ID and Service location
    # aco: accountable care organization
    # mco: managed care organization
    # pcc: Primary Care Clinician (PCC)
    # cp: Community Partners (CP) Program OR Care Plan (check context)
    # ltss: Long-Term Services and Supports
    # bh: Behavioural Health
    # bh cp: Behavioural Health *Community Partner*
    # ltss cp: Long-Term Services and Supports *Community Partner*
    # dds:  Department of Development Services
    # dms:  Department of Mental Health
    # dta:  Department of Transitional Assistance
    # dss:  Department of Children and Families (formerly Department of Social Services)
    # tpl: Third Party Liability
    # mmis: Medicaid Management Information System

    def self.schema_def
      <<~CSV.freeze
        ID,Field name,Description,Length,Data type,PRIVACY: former members
        1,member_id,Member's Medicaid identification number ,50,string,-
        2,performance_year,"Calendar/performance year during which the member is enrolled in a plan for the span segment (e.g. 2017). Spans are identified by calendar year except for CY 2018. Two separate spans are broken out to specify the period before and after the ACO program go-live in CY2018: (1) Between 1/1/18 and 2/28/18, the value is populated as “PreACO-2018” and (2) Between 3/1/18 and 12/31/18, the value is “PostACO-2018”.",50,string,-
        3,region,Managed care region a member resides,50,string,-
        4,service_area,Service area/geographic area covering member. A service area is within a managed care region,50,string,Redacted
        5,aco_pidsl,ACO entity ID. PIDSL is a combination of provider ID and service location,50,string,-
        6,aco_name,ACO name,255,string,-
        7,pcc_pidsl,PCC ID. PIDSL is a combination of provider ID and service location,50,string,-
        8,pcc_name,PCC name,255,string,-
        9,pcc_npi,PCC national provider identifier (NPI),50,string,-
        10,pcc_taxid,PCC tax identification number (TIN),50,string,-
        11,mco_pidsl,MCO entity ID. PIDSL is a combination of provider ID and service location,50,string,-
        12,mco_name,MCO name,50,string,-
        13,enrolled_flag,"Y/N flag if the span is active/current segment as of the last day of the reporting period. NOTE: the definition of this flag is different than that of ""enrolled_flag"" in the Membr roster.",50,string,-
        14,enroll_type,Enrollment type. Currently populates as null.,50,string,-
        15,enroll_stop_reason,Enrollment stop reason. Currently populates as null.,50,string,-
        16,rating_category_char_cd,Rating category,255,string,-
        17,ind_dds,Indicates whether member is affiliated with the Department of Development Services,50,string,Redacted
        18,ind_dmh,Indicates whether member is affiliated with the Department of Mental Health,50,string,Redacted
        19,ind_dta,Indicates whether member is affiliated with the Department of Transitional Assistance,50,string,Redacted
        20,ind_dss,Indicates whether member is affiliated with Department of Children and Families (formerly Department of Social Services),50,string,Redacted
        21,cde_hcb_waiver,Code to show member is enrolled in a home and community based services waiver,50,string,Redacted
        22,cde_waiver_category,More granular detail showing home and community based services waiver program member is enrolled in,50,string,Redacted
        23,span_start_date,Span start date,30,date (YYYY-MM-DD),-
        24,span_end_date,Span end date,30,date (YYYY-MM-DD),-
        25,span_mem_days,Span member days,10,int,-
        26,cp_prov_type,Community Partner (CP) Provider Type,255,string,-
        27,cp_plan_type,CP Assignment Plan Type,255,string,-
        28,cp_pidsl,CP entity ID. PIDSL is a combination of provider ID and service location,50,string,-
        29,cp_prov_name,CP Name,512,string,-
        30,cp_enroll_dt,Most recent CP enrollment date,30,date (YYYY-MM-DD),-
        31,cp_disenroll_dt,"Most recent CP disenrollment date. This field is bound by the reporting period, and any date that falls outside this reporting period will be nullified.",30,date (YYYY-MM-DD),-
        32,cp_start_rsn,Most recent CP start reason,255,string,-
        33,cp_stop_rsn,Most recent CP stop reason. Currently populates as null.,255,string,-
        34,ind_medicare_a,Indicates whether the member has Medicare Part A coverage ,50,string,-
        35,ind_medicare_b,Indicates whether the member has Medicare Part B coverage ,50,string,-
        36,tpl_coverage_cat,Coverage category type of the member’s verified TPL coverage,50,string,-
      CSV
    end

    # Figure out when the patient became engaged
    # save the engagement date
    # calculate the number of days engaged for the enrollment
    # note the span end when the calculation was done

    def self.maintain_engagement!
      engagement_claims_by_member_id = {}.tap do |claim_dates|
        ClaimsReporting::MedicalClaim.engaging.
          distinct.
          pluck(:member_id, :service_start_date).
          each do |member_id, service_start_date|
            claim_dates[member_id] ||= []
            claim_dates[member_id] << service_start_date
          end
      end

      unprocessed_engagement.find_in_batches do |enrollment_batch|
        update_batch = []
        enrollment_batch.each do |enrollment|
          claim_dates = engagement_claims_by_member_id[enrollment.member_id]
          next unless claim_dates

          # Find the most-recent claim date before the end of the enrollment
          # NOTE: we might need to adjust this for re-ups of care plans
          engagement_date = claim_dates.sort.reverse.detect { |d| d < enrollment.span_end_date }
          next unless engagement_date

          engagement_date = [enrollment.span_start_date, engagement_date].max
          days_engaged = enrollment.span_mem_days - (engagement_date - enrollment.span_start_date).to_i
          enrollment.assign_attributes(
            engagement_date: engagement_date,
            engaged_days: days_engaged,
            enrollment_end_at_engagement_calculation: enrollment.span_end_date,
          )
          update_batch << enrollment
        end
        import(update_batch, on_duplicate_key_update: [:engagement_date, :engaged_days, :enrollment_end_at_engagement_calculation])
      end
      # Add zeros for later calculations
      where(engagement_date: nil).update_all(engaged_days: 0)
    end

    def self.maintain_first_claim_date!
      min_claim_date_for = ClaimsReporting::MedicalClaim.group(:member_id).minimum(:service_start_date)
      batch = []
      # On the first enrollment per member, note the number of days since the first claim
      distinct_on(:member_id).
        order(member_id: :asc, span_start_date: :asc).each do |enrollment|
          date = min_claim_date_for[enrollment.member_id]
          next unless date

          enrollment.first_claim_date = date
          # Ignore any days before the first claim if it happens after the engagement date
          enrollment.pre_engagement_days = ([enrollment.engagement_date, enrollment.span_start_date, Date.current].compact.min - [date, enrollment.span_start_date].min).to_i
          batch << enrollment
        end
      transaction do
        update_all(first_claim_date: nil, pre_engagement_days: 0)
        import(batch, on_duplicate_key_update: [:first_claim_date, :pre_engagement_days])
      end
      # On all enrollments that still have 0 days pre-engaged, note time not engaged
      # This will include any enrollment where there are actually 0 days pre-engagement, and those that aren't the first enrollment
      batch = []
      where(pre_engagement_days: 0).each do |enrollment|
        enrollment.pre_engagement_days = enrollment.span_mem_days - enrollment.engaged_days
        batch << enrollment
      end
      transaction do
        import(batch, on_duplicate_key_update: [:pre_engagement_days])
      end
    end

    def span_date_range
      span_start_date .. span_end_date
    end

    # natural sort: by member id ASC, span_start_date ASC, span_end_date DESC
    # This is so that gaps are minimized should ranges overlap, since
    # we frequently are looking for minimal gaps
    include Comparable
    def <=>(other)
      raise ArgumentError, "#{inspect} cannot be sorted with #{other.inspect}" unless other.is_a?(self.class)

      diff = member_id <=> other.member_id
      diff = span_start_date <=> other.span_start_date if diff.zero?
      diff = other.span_end_date <=> span_end_date if diff.zero?

      diff
    end

    # The *most recent* (as of this MemberEnrollmentRoster) Community Provider
    # enrollment period. If a member was dis-enrolled the range will end on their
    # cp_disenroll_dt. Otherwise it ends on as_of which defaults to Date.current.
    #
    # While MemberEnrollmentRoster spans never cross a performance_year the
    # cp_enroll_dt is the latest date of community partner enrollment
    # even if that was in a prior measurement year
    def cp_enrolled_date_range(as_of: Date.current)
      return unless cp_enroll_dt

      end_dt = if cp_disenroll_dt && cp_disenroll_dt < as_of
        cp_enroll_dt
      else
        as_of
      end
      cp_enroll_dt .. end_dt
    end

    # Number of days of Community Provider in the *most recent* enrollment period.
    # As of the as_of date provided. See cp_enrolled_date_range for important notes.
    def cp_enrolled_days(as_of: Date.current)
      span = cp_enrolled_date_range(as_of: as_of)
      return 0 unless span

      # This is much faster than Range#count
      1 + (span.max - span.min)
    end
  end
end
