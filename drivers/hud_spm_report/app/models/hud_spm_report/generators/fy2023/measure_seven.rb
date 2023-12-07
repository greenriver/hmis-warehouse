###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Measure 2a and 2b: The Extent to which Persons Who Exit Homelessness
# to Permanent Housing Destinations Return to Homelessness within 6, 12,
# and 24 months.
module HudSpmReport::Generators::Fy2023
  class MeasureSeven < MeasureBase
    def self.question_number
      'Measure 7'.freeze
    end

    def self.table_descriptions
      {
        'Measure 7' => 'Successful Placement from Street Outreach and Successful Placement in or Retention of Permanent Housing',
        '7a.1' => 'Change in exits to permanent housing destinations',
        '7b.1' => 'Change in exits to permanent housing destinations',
        '7b.2' => 'Change in exit to or retention of permanent housing',
      }.freeze
    end

    def run_question!
      tables = [
        ['7a.1', :run_7a_1],
        ['7b.1', :run_7b_1],
        ['7b.2', :run_7b_2],
      ]

      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    COLUMNS = {
      'B' => 'Previous FY',
      'C' => 'Current FY',
      'D' => 'Difference',
    }.freeze

    private def run_7a_1(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Persons who exit Street Outreach',
          3 => 'Of persons above, those who exited to temporary & some institutional destinations',
          4 => 'Of the persons above, those who exited to permanent housing destinations',
          5 => '% Successful exits',
        },
        COLUMNS,
      )

      members = create_so_universe
      answer = @report.answer(question: table_name, cell: 'C2')
      answer.add_members(members)
      answer.update(summary: members.count)

      temporary = members.where(spm_e_t[:destination].in(TEMPORARY_AND_INSTITUTIONAL_DESTINATIONS))
      answer = @report.answer(question: table_name, cell: 'C3')
      answer.add_members(temporary)
      answer.update(summary: temporary.count)

      permanent = members.where(spm_e_t[:destination].in(PERMANENT_DESTINATIONS))
      answer = @report.answer(question: table_name, cell: 'C4')
      answer.add_members(permanent)
      answer.update(summary: permanent.count)

      answer = @report.answer(question: table_name, cell: 'C5')
      answer.update(summary: percent(temporary.count + permanent.count, members.count))
    end

    private def run_7b_1(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Persons in ES-EE, ES-NbN, SH, TH, and PH-RRH who exited, plus persons in other PH projects who exited without moving into housing',
          3 => 'Of the persons above, those who exited to permanent housing destinations',
          4 => '% Successful exits',
        },
        COLUMNS,
      )

      members = create_ph_no_move_in_universe
      answer = @report.answer(question: table_name, cell: 'C2')
      answer.add_members(members)
      answer.update(summary: members.count)

      permanent = members.where(spm_e_t[:destination].in(PERMANENT_DESTINATIONS))
      answer = @report.answer(question: table_name, cell: 'C3')
      answer.add_members(permanent)
      answer.update(summary: permanent.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      answer.update(summary: percent(permanent.count, members.count))
    end

    private def run_7b_2(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Persons in all PH projects except PH-RRH who exited after moving into housing, or who moved into housing and remained in the PH project',
          3 => 'Of persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations',
          4 => '% Successful exits/retention',
        },
        COLUMNS,
      )

      members = create_ph_universe
      answer = @report.answer(question: table_name, cell: 'C2')
      answer.add_members(members)
      answer.update(summary: members.count)

      permanent = members.where(spm_e_t[:destination].in(PERMANENT_DESTINATIONS))
      answer = @report.answer(question: table_name, cell: 'C3')
      answer.add_members(permanent)
      answer.update(summary: permanent.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      answer.update(summary: percent(permanent.count, members.count))
    end

    M7A_REJECTED = [
      206, # Hospital or other residential non-psychiatric medical facility
      329, # Residential project or halfway house with no homeless criteria
      24, # Deceased
    ].freeze

    M7B_REJECTED = [
      206, # Hospital or other residential non-psychiatric medical facility
      215, # Foster care home or foster care group home
      225, # Long-term care facility or nursing home
      24, # Deceased
    ].freeze

    TEMPORARY_AND_INSTITUTIONAL_DESTINATIONS = [
      101, # Emergency shelter, including hotel or motel paid for with emergency shelter voucher, Host Home shelter
      118, # Safe Haven

      215, # Foster care home or foster care group home
      204, # Psychiatric hospital or other psychiatric facility
      205, # Substance abuse treatment facility or detox center
      225, # Long-term care facility or nursing home

      314, # Hotel or motel paid for without emergency shelter voucher
      312, # Staying or living with family, temporary tenure
      313, # Staying or living with friends, temporary tenure
      302, # Transitional housing for homeless persons (including homeless youth)
      327, # Moved from one HOPWA funded project to HOPWA TH
      332, # Host Home (non-crisis)
    ].freeze

    PERMANENT_DESTINATIONS = [
      426, # Moved from one HOPWA funded project to HOPWA PH
      411, # Owned by client, no ongoing housing subsidy
      421, # Owned by client, with ongoing housing subsidy
      410, # Rental by client, no ongoing housing subsidy
      435, # Rental by client, with housing subsidy
      422, # Staying or living with family, permanent tenure
      423, # Staying or living with friends, permanent tenure
    ].freeze

    private def create_so_universe
      filter = ::Filters::HudFilterBase.new(user_id: User.system_user.id).update(@report.options)
      @universe = @report.universe(:m7a1)
      so_enrollments = enrollment_set.open_during_range(filter.range).where(project_type: HudUtility2024.project_type_number_from_code(:so))
      stayers = so_enrollments.where(spm_e_t[:exit_date].eq(nil).or(spm_e_t[:exit_date].gt(filter.end)))
      leavers = so_enrollments.where.not(id: stayers.select(:id))
      enrollments = HudSpmReport::Fy2023::SpmEnrollment.one_for_column(:exit_date, source_arel_table: spm_e_t, group_on: :client_id, scope: leavers)
      enrollments = enrollments.where.not(spm_e_t[:destination].in(M7A_REJECTED))

      members = enrollments.map do |enrollment|
        [enrollment.client, enrollment]
      end.to_h
      @universe.add_universe_members(members)

      @universe.members
    end

    private def create_ph_no_move_in_universe
      filter = ::Filters::HudFilterBase.new(user_id: User.system_user.id).update(@report.options)
      @universe = @report.universe(:m7b1)
      project_types = [:es, :sh, :th, :ph].map { |code| HudUtility2024.project_type_number_from_code(code) }.flatten
      open_enrollments = enrollment_set.open_during_range(filter.range).where(project_type: project_types)
      stayers = open_enrollments.where(spm_e_t[:exit_date].eq(nil).or(spm_e_t[:exit_date].gt(filter.end)))
      leavers = open_enrollments.where.not(id: stayers.select(:id))
      enrollments = HudSpmReport::Fy2023::SpmEnrollment.one_for_column(:exit_date, source_arel_table: spm_e_t, group_on: :client_id, scope: leavers)
      ph_not_rrh = HudUtility2024.project_type_number_from_code(:ph) - HudUtility2024.project_type_number_from_code(:rrh)
      enrollments = enrollments.where.not(spm_e_t[:project_type].in(ph_not_rrh).
        and(spm_e_t[:move_in_date].not_eq(nil).and(spm_e_t[:move_in_date].lteq(filter.end))))
      enrollments = enrollments.where.not(spm_e_t[:destination].in(M7B_REJECTED))

      members = enrollments.map do |enrollment|
        [enrollment.client, enrollment]
      end.to_h
      @universe.add_universe_members(members)

      @universe.members
    end

    private def create_ph_universe
      filter = ::Filters::HudFilterBase.new(user_id: User.system_user.id).update(@report.options)
      @universe = @report.universe(:m7b2)
      ph_not_rrh = HudUtility2024.project_type_number_from_code(:ph) - HudUtility2024.project_type_number_from_code(:rrh)
      open_enrollments = enrollment_set.open_during_range(filter.range).where(project_type: ph_not_rrh)
      stayers = open_enrollments.where(spm_e_t[:exit_date].eq(nil).or(spm_e_t[:exit_date].gt(filter.end)))
      latest_stays = HudSpmReport::Fy2023::SpmEnrollment.one_for_column(:entry_date, source_arel_table: spm_e_t, group_on: :client_id, scope: stayers)
      exclude = latest_stays.where(spm_e_t[:move_in_date].not_eq(nil).and(spm_e_t[:move_in_date].lteq(filter.end)))
      leavers = open_enrollments.where.not(client_id: exclude.select(:client_id))
      enrollments = HudSpmReport::Fy2023::SpmEnrollment.one_for_column(:exit_date, source_arel_table: spm_e_t, group_on: :client_id, scope: leavers)
      enrollments = enrollments.where.not(spm_e_t[:move_in_date].eq(nil))
      enrollments = enrollments.where.not(spm_e_t[:destination].in(M7B_REJECTED))

      members = enrollments.map do |enrollment|
        [enrollment.client, enrollment]
      end.to_h
      @universe.add_universe_members(members)

      @universe.members
    end
  end
end
