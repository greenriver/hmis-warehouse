###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportGenerators::SystemPerformance::Fy2019
  class MeasureSeven < Base
    LOOKBACK_STOP_DATE = '2012-10-01'

    # PH = [3,9,10,13]
    PH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:ph).flatten(1)
    # TH = [2]
    TH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:th).flatten(1)
    # ES = [1]
    ES = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:es).flatten(1)
    # SH = [8]
    SH = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:sh).flatten(1)
    # SO = [4]
    SO = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:so).flatten(1)

    RRH = [13]
    PH_PSH = [3,9,10] # All PH except 13, Measure 7 doesn't count RRH

    def run!
      # Disable logging so we don't fill the disk
      ActiveRecord::Base.logger.silence do
        calculate()
        Rails.logger.info "Done"
      end # End silence ActiveRecord Log
    end

   private
    def calculate
      if start_report(Reports::SystemPerformance::Fy2019::MeasureSeven.first)
        set_report_start_and_end()
        Rails.logger.info "Starting report #{@report.report.name}"
        # Overview:
        # 7a.1 Success of placement from Street Outreach (SO) at finding permanent housing
        # 7b.1 Success of placement from ES, SH, TH and PH-Rapid-Re-Housing at finding permanent housing
        # 7b.2 Success of PH (except Rapid Re-Housing) at finding permanent housing
        @answers = setup_questions()
        @support = @answers.deep_dup

        # Relevant Project Types/Program Types
        # 1: Emergency Shelter (ES)
        # 2: Transitional Housing (TH)
        # 3: Permanent Supportive Housing (disability required for entry) (PH)
        # 4: Street Outreach (SO)
        # 6: Services Only
        # 7: Other
        # 8: Safe Haven (SH)
        # 9: Permanent Housing (Housing Only) (PH)
        # 10: Permanent Housing (Housing with Services - no disability required for entry) (PH)
        # 11: Day Shelter
        # 12: Homeless Prevention
        # 13: Rapid Re-Housing (PH)
        # 14: Coordinated Entry

        calculate_7a_1()
        update_report_progress(percent: 33)
        calculate_7b_1()
        update_report_progress(percent: 66)
        calculate_7b_2()
        Rails.logger.info @answers
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end

    end

    def calculate_7a_1
      # Select clients who have a recorded stay in an SO during the report period
      # who also don't have an ongoing enrollment at an SO on the final day of the report
      # eg. Those who were counted by SO, but exited to somewhere else

      client_id_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          ongoing(on_date: @report_end).
          hud_project_type(SO)

      client_id_scope = add_filters(scope: client_id_scope)

      universe_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        open_between(start_date: @report_start,
          end_date: @report_end + 1.day).
        hud_project_type(SO).
        where.not(client_id: client_id_scope.
          select(:client_id).
          distinct
        )

      universe_scope = add_filters(scope: universe_scope)

      universe = universe_scope.
        select(:client_id).
        distinct.
        pluck(:client_id)

      destinations = {}
      universe.each do |id|
        destination_scope = GrdaWarehouse::ServiceHistoryEnrollment.exit.
          ended_between(start_date: @report_start,
          end_date: @report_end + 1.day).
          hud_project_type(SO).
          where(client_id: id)

        destination_scope = add_filters(scope: destination_scope)

        destinations[id] = destination_scope.
          order(date: :desc).
          limit(1).
          pluck(:destination).first
      end

      client_personal_ids = personal_ids(universe)

      remaining_leavers = destinations.reject{ |id, destination| [6, 29, 24].include?(destination.to_i)}
      @answers[:sevena1_c2][:value] = remaining_leavers.size
      @support[:sevena1_c2][:support] = {
        headers: ['Client ID', 'Personal IDs', 'Destination'],
        counts: remaining_leavers.map do |id, destination|
          [
            id,
            client_personal_ids[id].join(', '),
            HUD.destination(destination),
          ]
        end
      }

      temporary_leavers = destinations.select{ |id, destination| [1, 15, 14, 18, 27, 4, 12, 13, 5, 2, 25].include?(destination.to_i)}
      @answers[:sevena1_c3][:value] = temporary_leavers.size
      @support[:sevena1_c3][:support] = {
        headers: ['Client ID', 'Personal IDs', 'Destination'],
        counts: temporary_leavers.map do |id, destination|
          [
            id,
            client_personal_ids[id].join(', '),
            HUD.destination(destination),
          ]
        end
      }

      permanent_leavers = destinations.select{ |id, destination| (HUD.permanent_destinations - [24]).include?(destination.to_i)}
      @answers[:sevena1_c4][:value] = permanent_leavers.size
      @support[:sevena1_c4][:support] = {
        headers: ['Client ID', 'Personal IDs', 'Destination'],
        counts: permanent_leavers.map do |id, destination|
          [
            id,
            client_personal_ids[id].join(', '),
            HUD.destination(destination),
          ]
        end
      }

      top = (@answers[:sevena1_c3][:value].to_f + @answers[:sevena1_c4][:value].to_f)
      bottom = @answers[:sevena1_c2][:value]
      @answers[:sevena1_c5][:value] = (top / bottom * 100).round(2)

      return @answers
    end

    def calculate_7b_1
      # Select clients who have a recorded stay in ES, SH, TH and PH during the report period
      # who also don't have a "bed-night" at an ES, SH, TH and PH on the final day of the report
      # eg. Those who were counted by ES, SH, TH and PH, but exited to somewhere else
      # PH gets special treatment, 13 (RRH) is treated like ES,SH,TH, but 3,9,10
      # looks at housing move-in date and removes any where it is <= report_end
      client_id_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          ongoing(on_date: @report_end).
          hud_project_type(ES + SH + TH + PH)

      client_id_scope = add_filters(scope: client_id_scope)

      universe_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        open_between(start_date: @report_start,
          end_date: @report_end + 1.day).
        hud_project_type(ES + SH + TH + PH).
        where.not(client_id: client_id_scope.
          select(:client_id).
          distinct
        )

      universe_scope = add_filters(scope: universe_scope)

      universe = universe_scope.
        select(:client_id).
        distinct.
        pluck(:client_id)

      destinations = {}
      universe.each do |id|
        destination_scope = GrdaWarehouse::ServiceHistoryEnrollment.exit.
          ended_between(start_date: @report_start,
          end_date: @report_end + 1.day).
          hud_project_type(ES + SH + TH + PH).
          where(client_id: id)

        destination_scope = add_filters(scope: destination_scope)
        exit_data = destination_scope.joins(:enrollment).
          order(date: :desc).
          limit(1).
          pluck(:destination, :computed_project_type, e_t[:MoveInDate]).map do |destination, project_type, move_in_date|
            move_in_date = move_in_date.to_date if move_in_date.present?
            {
              destination: destination,
              project_type: project_type,
              move_in_date: move_in_date,
            }
          end.first
        next if exit_data.blank?
        # remove anyone who exited from PH, but had already moved into housing
        next if PH_PSH.include?(exit_data[:project_type].to_i) && exit_data[:move_in_date].present? && exit_data[:move_in_date] <= @report_end
        destinations[id] = exit_data[:destination]
      end

      client_personal_ids = personal_ids(universe)

      remaining_leavers = destinations.reject{ |id, destination| [15, 6, 25, 24].include?(destination.to_i)}
      @answers[:sevenb1_c2][:value] = remaining_leavers.size
      @support[:sevenb1_c2][:support] = {
        headers: ['Client ID', 'Personal IDs', 'Destination'],
        counts: remaining_leavers.map do |id, destination|
          [
            id,
            client_personal_ids[id].join(', '),
            HUD.destination(destination),
          ]
        end
      }

      permanent_leavers = destinations.select{ |id, destination| (HUD.permanent_destinations - [24]).include?(destination.to_i)}
      @answers[:sevenb1_c3][:value] = permanent_leavers.size
      @support[:sevenb1_c3][:support] = {
        headers: ['Client ID', 'Personal IDs', 'Destination'],
        counts: permanent_leavers.map do |id, destination|
          [
            id,
            client_personal_ids[id].join(', '),
            HUD.destination(destination),
          ]
        end
      }

      top = @answers[:sevenb1_c3][:value].to_f
      bottom = @answers[:sevenb1_c2][:value]
      @answers[:sevenb1_c4][:value] = (top / bottom * 100).round(2)
      return @answers
    end

    def calculate_7b_2
      # Select clients who have a recorded stay in PH but not PH-RRH during the report period
      # who also don't have an ongoing enrollment at a PH but not PH-RRH on the final day of the report
      # eg. Those who were counted by PH but not PH-RRH, but exited to somewhere else

      client_id_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          ongoing(on_date: @report_end).
          hud_project_type(PH_PSH)

      client_id_scope = add_filters(scope: client_id_scope)

      leavers_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        open_between(start_date: @report_start,
        end_date: @report_end + 1.day).
        hud_project_type(PH_PSH).
        where.not(client_id: client_id_scope.
          select(:client_id).
          distinct
        )

      leavers_scope = add_filters(scope: leavers_scope)

      leavers = leavers_scope.
        select(:client_id).
        distinct.
        pluck(:client_id)

      stayers_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        ongoing(on_date: @report_end).
        hud_project_type(PH_PSH)

      stayers_scope = add_filters(scope: stayers_scope)

      stayers = Set.new
      stayers_scope.joins(:enrollment).
        select(:client_id).
        distinct.
        order(first_date_in_program: :asc).
        pluck(:client_id, :first_date_in_program, e_t[:MoveInDate]).
        group_by(&:first).each do |_, stays|
          (client_id, entry_date, move_in_date) = stays.last
          # remove anyone who hasn't moved in to housing yet
          # Some old enrollments don't have move-in-dates
          next if (move_in_date.blank? || move_in_date > @report_end) && entry_date.to_date > '2015-01-01'.to_date
          stayers << client_id
        end

      destinations = {}
      leavers.each do |id|
        destination_scope = GrdaWarehouse::ServiceHistoryEnrollment.exit.
          joins(:enrollment).
          ended_between(start_date: @report_start,
          end_date: @report_end + 1.day).
          hud_project_type(PH).
          where(client_id: id)

        destination_scope = add_filters(scope: destination_scope)
        exit_data = destination_scope.
          order(date: :desc).
          limit(1).
          pluck(:destination, :computed_project_type, e_t[:MoveInDate]).map do |destination, project_type, move_in_date|
            {
              destination: destination,
              project_type: project_type,
              move_in_date: move_in_date,
            }
          end.first
        # remove anyone who exited from PH, but never moved into housing
        next if exit_data.blank? || exit_data[:move_in_date].blank?
        destinations[id] = exit_data[:destination]
      end

      client_personal_ids = personal_ids(leavers)

      remaining_leavers = destinations.reject{ |id, destination| [15, 6, 25, 24].include?(destination.to_i)}
      @answers[:sevenb2_c2][:value] = remaining_leavers.size + stayers.size
      @support[:sevenb2_c2][:support] = {
        headers: ['Client ID', 'Personal IDs', 'Destination'],
        counts: remaining_leavers.map do |id, destination|
          [
            id,
            client_personal_ids[id].join(', '),
            HUD.destination(destination),
          ]
        end
      }

      permanent_leavers = destinations.select{ |id, destination| (HUD.permanent_destinations - [24]).include?(destination.to_i)}
      @answers[:sevenb2_c3][:value] = permanent_leavers.size + stayers.size
      @support[:sevenb2_c3][:support] = {
        headers: ['Client ID', 'Personal IDs', 'Destination'],
        counts: permanent_leavers.map do |id, destination|
          [
            id,
            client_personal_ids[id].join(', '),
            HUD.destination(destination),
          ]
        end
      }

      top = @answers[:sevenb2_c3][:value].to_f
      bottom = @answers[:sevenb2_c2][:value]
      @answers[:sevenb2_c4][:value] = (top / bottom * 100).round(2)
      return @answers
    end

    def setup_questions
      {
        sevena1_a2: {
          title: nil,
          value: 'Universe: Persons who exit Street Outreach',
        },
        sevena1_a3: {
          title: nil,
          value: 'Of persons above, those who exited to temporary & some institutional destinations',
        },
        sevena1_a4: {
          title: nil,
          value: 'Of the persons above, those who exited to permanent housing destinations',
        },
        sevena1_a5: {
          title: nil,
          value: '% Successful exits',
        },
        sevena1_b1: {
          title: nil,
          value: 'Previous FY',
        },
        sevena1_b2: {
          title: 'Universe: Persons who exit Street Outreach (previous FY)',
          value: nil,
        },
        sevena1_b3: {
          title: 'Of persons above, those who exited to temporary & some institutional destinations (previous FY)',
          value: nil,
        },
        sevena1_b4: {
          title: 'Of the persons above, those who exited to permanent housing destinations (previous FY)',
          value: nil,
        },
        sevena1_b5: {
          title: '% Successful exits (previous FY)',
          value: nil,
        },
        sevena1_c1: {
          title: nil,
          value: 'Current FY',
        },
        sevena1_c2: {
          title: 'Universe: Persons who exit Street Outreach (current FY)',
          value: 0,
        },
        sevena1_c3: {
          title: 'Of persons above, those who exited to temporary & some institutional destinations (current FY)',
          value: 0,
        },
        sevena1_c4: {
          title: 'Of the persons above, those who exited to permanent housing destinations (current FY)',
          value: 0,
        },
        sevena1_c5: {
          title: '% Successful exits (current FY)',
          value: 0,
        },
        sevena1_d1: {
          title: nil,
          value: '% Difference',
        },
        sevena1_d2: {
          title: 'Universe: Persons who exit Street Outreach (% difference)',
          value: nil,
        },
        sevena1_d3: {
          title: 'Of persons above, those who exited to temporary & some institutional destinations (% difference)',
          value: nil,
        },
        sevena1_d4: {
          title: 'Of the persons above, those who exited to permanent housing destinations (% difference)',
          value: nil,
        },
        sevena1_d5: {
          title: '% Successful exits (% difference)',
          value: nil,
        },
        sevenb1_a2: {
          title: nil,
          value: 'Universe: Persons in ES, SH, TH and PH-RRH who exited',
        },
        sevenb1_a3: {
          title: nil,
          value: 'Of the persons above, those who exited to permanent housing destinations',
        },
        sevenb1_a4: {
          title: nil,
          value: '% Successful exits',
        },
        sevenb1_b1: {
          title: nil,
          value: 'Previous FY',
        },
        sevenb1_b2: {
          title: 'Universe: Persons in ES, SH, TH and PH-RRH who exited (previous FY)',
          value: nil,
        },
        sevenb1_b3: {
          title: 'Of the persons above, those who exited to permanent housing destinations (previous FY)',
          value: nil,
        },
        sevenb1_b4: {
          title: '% Successful exits (previous FY)',
          value: nil,
        },
        sevenb1_c1: {
          title: nil,
          value: 'Current FY',
        },
        sevenb1_c2: {
          title: 'Universe: Persons in ES, SH, TH and PH-RRH who exited (current FY)',
          value: 0,
        },
        sevenb1_c3: {
          title: 'Of the persons above, those who exited to permanent housing destinations (current FY)',
          value: 0,
        },
        sevenb1_c4: {
          title: '% Successful exits (current FY)',
          value: 0,
        },
        sevenb1_d1: {
          title: nil,
          value: '% Difference',
        },
        sevenb1_d2: {
          title: 'Universe: Persons in ES, SH, TH and PH-RRH who exited (% difference)',
          value: nil,
        },
        sevenb1_d3: {
          title: 'Of the persons above, those who exited to permanent housing destinations (% difference)',
          value: nil,
        },
        sevenb1_d4: {
          title: '% Successful exits (% difference)',
          value: nil,
        },
        sevenb2_a2: {
          title: nil,
          value: 'Universe: Persons in all PH projects except PH-RRH',
        },
        sevenb2_a3: {
          title: nil,
          value: 'Of the persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations',
        },
        sevenb2_a4: {
          title: nil,
          value: '% Successful exits/retentions',
        },
        sevenb2_b1: {
          title: nil,
          value: 'Previous FY',
        },
        sevenb2_b2: {
          title: 'Universe: Persons in all PH projects except PH-RRH (previous FY)',
          value: nil,
        },
        sevenb2_b3: {
          title: 'Of the persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations (previous FY)',
          value: nil,
        },
        sevenb2_b4: {
          title: '% Successful exits/retentions (previous FY)',
          value: nil,
        },
        sevenb2_c1: {
          title: nil,
          value: 'Current FY',
        },
        sevenb2_c2: {
          title: 'Universe: Persons in all PH projects except PH-RRH (current FY)',
          value: 0,
        },
        sevenb2_c3: {
          title: 'Of the persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations (current FY)',
          value: 0,
        },
        sevenb2_c4: {
          title: '% Successful exits/retentions (current FY)',
          value: 0,
        },
        sevenb2_d1: {
          title: nil,
          value: '% Difference',
        },
        sevenb2_d2: {
          title: 'Universe: Persons in all PH projects except PH-RRH (% difference)',
          value: nil,
        },
        sevenb2_d3: {
          title: 'Of the persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations (% difference)',
          value: nil,
        },
        sevenb2_d4: {
          title: '% Successful exits/retentions (% difference)',
          value: nil,
        },
      }
    end
  end
end
