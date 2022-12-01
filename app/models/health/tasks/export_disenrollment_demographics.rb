###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'csv'

module Health::Tasks
  class ExportDisenrollmentDemographics
    include ArelHelper

    def initialize(filename:, start_date:, end_date:)
      @filename = filename
      @start_date = start_date
      @end_date = end_date
    end

    def run!
      CSV.open(@filename, 'wb') do |csv|
        csv << ['Race']
        HUD.races(multi_racial: true).keys.each do |key|
          disenrolled = demographics.values.select(&:reason).count { |client| client[:race] == key }
          total = demographics.values.count { |client| client[:race] == key }
          csv << [HUD.race(key, multi_racial: true), disenrolled, percentage(disenrolled, patient_universe.count), total, percentage(total, patient_universe.count)]
        end

        csv << []
        csv << ['Gender']
        HUD.genders.values.each do |key|
          disenrolled = demographics.values.select(&:reason).count { |client| client[:gender] == key }
          total = demographics.values.count { |client| client[:gender] == key }
          csv << [key, disenrolled, percentage(disenrolled, patient_universe.count), total, percentage(total, patient_universe.count)]
        end

        csv << []
        csv << ['Ethnicity']
        HUD.ethnicities.values.each do |key|
          disenrolled = demographics.values.select(&:reason).count { |client| client[:ethnicity] == key }
          total = demographics.values.count { |client| client[:ethnicity] == key }
          csv << [key, disenrolled, percentage(disenrolled, patient_universe.count), total, percentage(total, patient_universe.count)]
        end

        csv << []
        csv << ['Language']
        demographics.values.map(&:language).uniq.each do |key|
          disenrolled = demographics.values.select(&:reason).count { |client| client[:language] == key }
          total = demographics.values.count { |client| client[:language] == key }
          csv << [key, disenrolled, percentage(disenrolled, patient_universe.count), total, percentage(total, patient_universe.count)]
        end

        csv << []
        csv << ['Disenrollment Reason']
        demographics.values.map(&:reason).uniq.each do |key|
          next if key.blank?

          total = demographics.values.count { |client| client[:reason] == key }
          csv << [key, total, percentage(total, patient_leavers.count)]
        end

        csv << []
        csv << ['Counts']

        csv << ['Universe', patient_universe.count]
        csv << ['Leavers', patient_leavers.count, percentage(patient_leavers.count, patient_universe.count)]
      end
    end

    private def patient_universe
      @patient_universe ||= Health::Patient.
        distinct.
        joins(:patient_referrals).
        merge(Health::PatientReferral.active_within_range(start_date: @start_date, end_date: @end_date))
    end

    private def patient_leavers
      @patient_leavers ||= patient_universe.merge(Health::PatientReferral.current).where(hpr_t[:disenrollment_date].lteq(@end_date))
    end

    private def race(client)
      fields = client.race_fields
      return 'MultiRacial' if fields.many?
      return 'RaceNone' if fields.empty?

      fields.first
    end

    private def gender(client)
      HUD.gender(client.gender_binary)
    end

    private def ethnicity(client)
      client.ethnicity_description
    end

    private def demographics
      @demographics ||= begin
        demographics = {}.tap do |h|
          GrdaWarehouse::Hud::Client.where(id: patient_universe.pluck(:client_id)).find_each do |client|
            h[client.patient.medicaid_id] = OpenStruct.new(
              race: race(client),
              gender: gender(client),
              ethnicity: ethnicity(client),
              language: 'BLANK',
              reason: nil,
            )
          end
        end

        ClaimsReporting::MemberRoster.where(member_id: patient_universe.pluck(:medicaid_id)).find_each do |member|
          struct = demographics[member.member_id]
          next unless struct

          language = member.primary_language_s.strip
          language = 'BLANK' if language.blank?
          struct.language = language
        end

        patient_leavers.find_each do |patient|
          next if patient.patient_referral.rejected_reason == 'Remove_Removal'

          reason = patient.patient_referral.rejected_reason || 'Unknown'
          demographics[patient.medicaid_id].reason = reason.humanize
        end

        demographics
      end
    end

    private def percentage(count, universe_size)
      (count * 100.0 / universe_size).round(2)
    end
  end
end
