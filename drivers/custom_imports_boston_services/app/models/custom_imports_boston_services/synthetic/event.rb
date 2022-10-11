###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonServices::Synthetic
  class Event < ::GrdaWarehouse::Synthetic::Event
    include ArelHelper

    validates_presence_of :source

    EVENT_LOOKUP = {
      # ['', ''] => 1, # 'Referral to Prevention Assistance project'
      ['Diversion', 'Diverted from Shelter'] => 2, # 'Problem Solving/Diversion/Rapid Resolution intervention or service'
      # ['', ''] => 3, # 'Referral to scheduled Coordinated Entry Crisis Needs Assessment'
      ['Referral to Housing Needs Assessment', 'RRH to PSH Transfer Assessment'] => 4, # 'Referral to scheduled Coordinated Entry Housing Needs Assessment'
      ['Coordinated Entry Event', 'RRH to PSH Transfer Assessment completion'] => 4, # 'Referral to scheduled Coordinated Entry Housing Needs Assessment'
      ['Coordinated Entry Event', 'Pathways Housing Assessment completion'] => 4, # 'Referral to scheduled Coordinated Entry Housing Needs Assessment'
      # ['', ''] => 5, # 'Referral to Post-placement/ follow-up case management'
      # ['', ''] => 6, # 'Referral to Street Outreach project or services'
      ['Coordinated Entry Referrals', 'Referral to Housing Navigation project or services'] => 7, # 'Referral to Housing Navigation project or services'
      ['Referral to Services Not Provided by FDT', 'Referral to Non-continuum services: Ineligible for continuum services'] => 8, # 'Referral to Non-continuum services: Ineligible for continuum services'
      ['Referral to Services Not Provided by FDT', 'Referral to Immigration Services'] => 9, # 'Referral to Non-continuum services: No availability in continuum services'
      ['Referral to Services Not Provided by FDT', 'Referral to Youth Services'] => 9, # 'Referral to Non-continuum services: No availability in continuum services'
      ['Referral to Services Not Provided by FDT', 'Referral to Employment Services'] => 9, # 'Referral to Non-continuum services: No availability in continuum services'
      ['Referral to Services Not Provided by FDT', 'Referral to Mental Health Services'] => 9, # 'Referral to Non-continuum services: No availability in continuum services'
      ['Referral to Services Not Provided by FDT', 'Referral to Substance Use Services'] => 9, # 'Referral to Non-continuum services: No availability in continuum services'
      ['Referral to Services Not Provided by FDT', 'Referral to Prevention Assistance project'] => 9, # 'Referral to Non-continuum services: No availability in continuum services'
      ['Referral to Services Not Provided by FDT', 'Referral to Veteran Services'] => 9, # 'Referral to Non-continuum services: No availability in continuum services'
      ['Referral to Services Not Provided by FDT', 'Referral to Medical/PCP'] => 9, # 'Referral to Non-continuum services: No availability in continuum services'
      ['Referral to Services Not Provided by FDT', 'Referral to Housing Navigation project or services'] => 9, # 'Referral to Non-continuum services: No availability in continuum services'
      ['Referral to Services Not Provided by FDT', 'Referral to Domestic Violence Services'] => 9, # 'Referral to Non-continuum services: No availability in continuum services'
      ['Referral to Services Not Provided by FDT', 'Referral to post-placement/follow-up case management'] => 9, # 'Referral to Non-continuum services: No availability in continuum services'
      ['Coordinated Entry Referrals', 'Referral to Income Maximization services'] => 9, # 'Referral to Non-continuum services: No availability in continuum services'
      ['Referral to Emergency Shelter', 'Referral to Emergency Shelter'] => 10, # 'Referral to Emergency Shelter bed opening'
      ['Referral to Emergency Shelter', 'Referral to Women\'s Inn'] => 10, # 'Referral to Emergency Shelter bed opening'
      ['Referral to Emergency Shelter', 'Referral to Charles River Inn'] => 10, # 'Referral to Emergency Shelter bed opening'
      ['Referral to Emergency Shelter', 'Referral to Holy Family Inn'] => 10, # 'Referral to Emergency Shelter bed opening'
      ['Referral to Emergency Shelter', 'Referral to Shattuck Shelter'] => 10, # 'Referral to Emergency Shelter bed opening'
      ['Referral to Emergency Shelter', 'Referral to Men\'s Inn'] => 10, # 'Referral to Emergency Shelter bed opening'
      # ['', ''] => 11, # 'Referral to Transitional Housing bed/unit opening'
      # ['', ''] => 12, # 'Referral to Joint TH-RRH project/unit/resource opening'
      # ['', ''] => 13, # 'Referral to RRH project resource opening'
      # ['', ''] => 14, # 'Referral to PSH project resource opening'
      # ['', ''] => 15, # 'Referral to Other PH project/unit/resource opening'
      # ['', ''] => 16, # 'Referral to emergency assistance/flex fund/furniture assistance'
      # ['', ''] => 17, # 'Referral to Emergency Housing Voucher (EHV)'
      # ['', ''] => 18, # 'Referral to a Housing Stability Voucher'
    }.freeze

    def self.event_event(source)
      EVENT_LOOKUP[[source.service_name, source.service_item]]
    end

    def event_date
      source.date
    end

    def event
      self.class.event_event(source)
    end

    def data_source
      'Clarity Custom Import'
    end

    def referral_result
      nil
    end

    def result_date
      nil
    end

    def self.sync
      remove_orphans
      add_new
    end

    def self.remove_orphans
      orphan_ids = pluck(:source_id) - CustomImportsBostonServices::Row.joins(:service).event_eligible.pluck(:id)
      return unless orphan_ids.present?

      where(source_id: orphan_ids).delete_all
    end

    def self.add_new
      rows = CustomImportsBostonServices::Row.joins(:service).event_eligible.where.not(id: self.select(:source_id)).preload(:enrollment)
      rows.find_in_batches do |batch|
        event_batch = []
        batch.each do |row|
          next unless row.client.present?
          next unless row.date.present?

          enrollment = row.enrollment
          next unless enrollment.present?

          event_batch << {
            source_id: row.id,
            source_type: row.class.name,
            enrollment_id: enrollment.id,
            client_id: row.client.id,
          }
        end
        CustomImportsBostonServices::Synthetic::Event.import(
          event_batch,
          conflict_target: [:source_id, :source_type],
          columns: [:enrollment_id, :client_id],
        )
      end
    end
  end
end
