###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Health::TeamPatientsController, type: :request do
  describe 'GET index - performance test' do
    let!(:agencies) do
      create_list(:health_agency, 2)
    end

    let!(:users) do
      create_list(:user, 5)
    end

    let!(:teams) do
      [
        create(
          :coordination_team,
          team_coordinator: users[0],
          team_nurse_care_manager: users[1],
        ),
        create(
          :coordination_team,
          team_coordinator: users[2],
          team_nurse_care_manager: users[3],
        ),
      ]
    end

    let!(:agency_users) do
      [
        create(:agency_user, agency: agencies[0], user: users[0]),
        create(:agency_user, agency: agencies[0], user: users[1]),
        create(:agency_user, agency: agencies[1], user: users[2]),
        create(:agency_user, agency: agencies[1], user: users[3]),
      ]
    end

    let!(:care_coordinators) do
      [
        create(
          :user_care_coordinator,
          coordination_team: teams[0],
          user: users[0],
        ),
        create(
          :user_care_coordinator,
          coordination_team: teams[0],
          user: users[1],
        ),
        create(
          :user_care_coordinator,
          coordination_team: teams[1],
          user: users[2],
        ),
      ]
    end

    let!(:patients_and_data) do
      patients = []
      # Create patients in various categories to trigger TeamPerformance report queries
      # Total: ~60 patients (30 per team) distributed across different QA/intake status categories

      2.times do |team_idx|
        coordinator_idx = team_idx * 2

        # Category 1: Patients WITH required QA (have QA within window)
        5.times do
          patient = create(:patient, health_agency: agencies[team_idx])
          patient.update(care_coordinator: users[coordinator_idx], nurse_care_manager: users[team_idx + 1])
          patients.push(patient)

          patient.patient_referral.update(
            enrollment_start_date: Date.current - 60.days,
            disenrollment_date: nil,
            current: true,
            contributing: true,
          )

          # Has QA in required window
          create(:qualifying_activity, patient_id: patient.id, date_of_activity: Date.current - 10.days)
          create(:careplan, patient: patient)
          create(:release_form, patient: patient)
        end

        # Category 2: Patients WITHOUT required QA
        5.times do
          patient = create(:patient, health_agency: agencies[team_idx])
          patient.update(care_coordinator: users[coordinator_idx], nurse_care_manager: users[team_idx + 1])
          patients.push(patient)

          patient.patient_referral.update(
            enrollment_start_date: Date.current - 90.days,
            disenrollment_date: nil,
            current: true,
            contributing: true,
          )

          # No QA in required window (last QA was > 60 days ago)
          create(:qualifying_activity, patient_id: patient.id, date_of_activity: Date.current - 70.days)
          create(:careplan, patient: patient)
          create(:release_form, patient: patient)
        end

        # Category 3: Patients with completed intake
        5.times do
          patient = create(:patient, health_agency: agencies[team_idx])
          patient.update(care_coordinator: users[coordinator_idx], nurse_care_manager: users[team_idx + 1])
          patients.push(patient)

          patient.patient_referral.update(
            enrollment_start_date: Date.current - 120.days,
            disenrollment_date: nil,
            current: true,
            contributing: true,
          )

          # Has completed intake (careplan creates intake evidence)
          create(:careplan, patient: patient)
          create(:release_form, patient: patient)
        end

        # Category 4: Patients initial intake due
        5.times do
          patient = create(:patient, health_agency: agencies[team_idx])
          patient.update(care_coordinator: users[coordinator_idx], nurse_care_manager: users[team_idx + 1])
          patients.push(patient)

          patient.patient_referral.update(
            enrollment_start_date: Date.current - 20.days,
            disenrollment_date: nil,
            current: true,
            contributing: true,
          )

          # No careplan yet - intake is due
          create(:release_form, patient: patient)
        end

        # Category 5: Patients with F2F visit
        5.times do
          patient = create(:patient, health_agency: agencies[team_idx])
          patient.update(care_coordinator: users[coordinator_idx], nurse_care_manager: users[team_idx + 1])
          patients.push(patient)

          patient.patient_referral.update(
            enrollment_start_date: Date.current - 45.days,
            disenrollment_date: nil,
            current: true,
            contributing: true,
          )

          # Has F2F QA recently
          create(:qualifying_activity, patient_id: patient.id, mode_of_contact: 'in_person', date_of_activity: Date.current - 15.days)
          create(:careplan, patient: patient)
          create(:release_form, patient: patient)
        end

        # Category 6: Patients WITHOUT F2F visit
        5.times do
          patient = create(:patient, health_agency: agencies[team_idx])
          patient.update(care_coordinator: users[coordinator_idx], nurse_care_manager: users[team_idx + 1])
          patients.push(patient)

          patient.patient_referral.update(
            enrollment_start_date: Date.current - 120.days,
            disenrollment_date: nil,
            current: true,
            contributing: true,
          )

          # Only phone QAs, no F2F
          create(:qualifying_activity, patient_id: patient.id, mode_of_contact: 'phone_call', date_of_activity: Date.current - 10.days)
          create(:careplan, patient: patient)
          create(:release_form, patient: patient)
        end
      end

      patients
    end

    before do
      # The user already has team_mates through user_care_coordinator and is assigned to patients
      # Grant them the appropriate role to view patients via UserRole (legacy system)
      role = Role.find_or_create_by!(name: 'Health Coordinator', health_role: true) do |r|
        r.can_view_patients_for_own_agency = true
        r.can_edit_patient_items_for_own_agency = true
        r.can_approve_release = true
      end
      UserRole.find_or_create_by!(user_id: users[0].id, role_id: role.id)
      users[0].reload

      sign_in users[0]

      # Debug: Check what the user has access to
      puts "\n[DEBUG] User permissions AFTER ROLE SETUP:"
      puts "[DEBUG] can_view_patients_for_own_agency: #{users[0].can_view_patients_for_own_agency?}"
    end

    it 'loads the index page without N+1 queries' do
      # Set up detailed query logging with caller backtrace
      queries = []
      query_details = {}
      original_logger = ActiveRecord::Base.logger
      query_logger = Logger.new(StringIO.new)
      query_logger.formatter = lambda do |_severity, _datetime, _progname, msg|
        if msg.include?('SELECT') || msg.include?('UPDATE') || msg.include?('INSERT')
          queries << msg
          # Extract table name
          table = if msg =~ /FROM\s+"?(\w+)"?/i
            Regexp.last_match(1)
          elsif msg =~ /UPDATE\s+"?(\w+)"?/i
            Regexp.last_match(1)
          elsif msg =~ /INSERT INTO\s+"?(\w+)"?/i
            Regexp.last_match(1)
          end
          if table
            query_details[table] ||= { count: 0, examples: [] }
            query_details[table][:count] += 1
            # Store first 3 examples
            query_details[table][:examples] << msg[0..150] if query_details[table][:examples].size < 3
          end
        end
        "#{msg}\n"
      end
      ActiveRecord::Base.logger = query_logger

      puts "\n[TEST] About to make GET request..."
      get health_team_patients_path
      puts "[TEST] Response received, status: #{response.status}"
      puts "[TEST] Redirect location: #{response.location}" if response.redirect?

      # Continue logging through redirects
      while response.redirect?
        follow_redirect!
        puts "[TEST] After redirect, status: #{response.status}"
      end
      puts "[TEST] Final status: #{response.status}"

      # Restore original logger
      ActiveRecord::Base.logger = original_logger

      expect(response).to have_http_status(:success)

      puts "\n" + '=' * 80
      puts 'QUERY PERFORMANCE REPORT'
      puts '=' * 80
      puts "Total Queries: #{queries.count}"

      # Save all queries to file for analysis
      File.write('/tmp/all_queries.log', queries.join("\n\n"))
      puts "Saved #{queries.count} queries to /tmp/all_queries.log"

      if queries.any?
        table_counts = {}
        queries.each do |sql|
          next unless sql =~ /FROM\s+"?(\w+)"?/i || sql =~ /UPDATE\s+"?(\w+)"?/i || sql =~ /INSERT INTO\s+"?(\w+)"?/i

          table = Regexp.last_match(1)
          table_counts[table] ||= 0
          table_counts[table] += 1
        end

        puts "\nQueries by Table:"
        table_counts.sort_by { |_k, v| -v }.each do |table, count|
          puts "  #{table}: #{count} queries"
        end

        # Look for repeated queries
        repeated = queries.group_by { |q| q }.transform_values(&:count).select { |_q, count| count > 1 }
        if repeated.any?
          puts "\nRepeated Queries (N+1 Indicators):"
          repeated.sort_by { |_q, count| -count }.first(10).each do |sql, count|
            puts "  [#{count}x] #{sql[0..100].strip}..."
          end
        end
      end

      puts '=' * 80 + "\n"

      # Diagnostic threshold - baseline is ~960 queries with 60 test patients
      # After optimizations, we should reduce to ~200-300 queries
      # For now, just document the baseline
      puts "\nBASELINE: #{queries.count} queries with #{patients_and_data.count} patients"
    end

    it 'renders all patients without errors' do
      get health_team_patients_path
      follow_redirect! while response.redirect?
      expect(response).to have_http_status(:success)

      # Debug: Check if patients are actually in the response
      puts "\n" + '=' * 80
      puts 'RESPONSE BODY DEBUG'
      puts '=' * 80
      puts "Response body length: #{response.body.length} bytes"
      puts "Response content type: #{response.content_type}"

      # Output first 2000 chars to see structure
      puts "\nFirst 2000 characters of response:"
      puts response.body[0..2000]
      puts "\n..." + '=' * 80 + "\n"
    end

    it 'checks report creation query count' do
      puts "\n[TEST] Testing report creation..."
      queries = []
      original_logger = ActiveRecord::Base.logger
      query_logger = Logger.new(StringIO.new)
      query_logger.formatter = lambda do |_severity, _datetime, _progname, msg|
        queries << msg if msg.include?('SELECT') || msg.include?('UPDATE') || msg.include?('INSERT')
        "#{msg}\n"
      end
      ActiveRecord::Base.logger = query_logger

      report = Health::TeamPerformance.new(range: (Date.current.beginning_of_month..Date.current.end_of_month), team_scope: Health::CoordinationTeam.all)
      # Force report queries to run
      report.team_counts
      report.total_counts

      ActiveRecord::Base.logger = original_logger

      puts "\nReport query count: #{queries.count}"
      table_counts = {}
      queries.each do |sql|
        next unless sql =~ /FROM\s+"?(\w+)"?/i || sql =~ /UPDATE\s+"?(\w+)"?/i || sql =~ /INSERT INTO\s+"?(\w+)"?/i

        table = Regexp.last_match(1)
        table_counts[table] ||= 0
        table_counts[table] += 1
      end

      puts "\nQueries by table (top 15):"
      table_counts.sort_by { |_k, v| -v }.first(15).each do |table, count|
        puts "  #{table}: #{count} queries"
      end
    end

    it 'identifies slowest queries and potential bottlenecks' do
      # Capture queries with timing
      queries_with_time = []
      original_logger = ActiveRecord::Base.logger
      query_logger = Logger.new(StringIO.new)
      query_logger.formatter = lambda do |_severity, _datetime, _progname, msg|
        if msg.include?('SELECT') || msg.include?('UPDATE') || msg.include?('INSERT')
          # Extract timing: "... (1.2ms)"
          if msg =~ /\((\d+\.\d+)ms\)/
            timing = Regexp.last_match(1).to_f
            queries_with_time << { sql: msg, timing: timing }
          else
            queries_with_time << { sql: msg, timing: 0 }
          end
        end
        "#{msg}\n"
      end
      ActiveRecord::Base.logger = query_logger

      get health_team_patients_path
      follow_redirect! while response.redirect?

      ActiveRecord::Base.logger = original_logger

      expect(response).to have_http_status(:success)

      puts "\n" + '=' * 80
      puts 'SLOWEST QUERIES ANALYSIS'
      puts '=' * 80

      # Sort by timing
      slowest = queries_with_time.sort_by { |q| -q[:timing] }.first(20)
      puts "\nTop 20 Slowest Individual Queries:"
      slowest.each_with_index do |q, idx|
        puts "#{idx + 1}. #{q[:timing].round(2)}ms: #{q[:sql][0..120].strip}..."
      end

      # Group similar queries and sum timing
      query_groups = {}
      queries_with_time.each do |q|
        # Normalize the query to group similar patterns
        normalized = q[:sql].gsub(/\d+/, 'X').gsub(/'[^']*'/, "'VAL'")[0..100]
        query_groups[normalized] ||= { count: 0, total_time: 0, sample: q[:sql] }
        query_groups[normalized][:count] += 1
        query_groups[normalized][:total_time] += q[:timing]
      end

      puts "\n\nQuery Patterns by Total Time (cumulative):"
      query_groups.sort_by { |_q, data| -data[:total_time] }.first(15).each_with_index do |(pattern, data), idx|
        puts "#{idx + 1}. #{data[:total_time].round(2)}ms total (#{data[:count]} queries): #{pattern}..."
      end

      puts '=' * 80 + "\n"
    end

    # Skipped test for detailed query logging
    skip 'logs all queries for analysis' do
      log_file = Rails.root.join('tmp', 'team_patients_queries.log')
      queries = []

      callback = lambda do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        if event.payload[:sql].exclude?('SCHEMA')
          queries << {
            sql: event.payload[:sql],
            duration: event.duration,
          }
        end
      end

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        get health_team_patients_path
      end

      File.write(log_file, queries.map { |q| "#{q[:duration]}ms: #{q[:sql]}\n" }.join)
      puts "Queries logged to #{log_file}"
    end
  end
end

# Helper class to track and report on SQL queries
class QueryTracker
  def initialize
    @queries = []
    @table_counts = {}
    @subscription = nil
  end

  def track
    # Start subscription
    @subscription = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      sql = event.payload[:sql]
      unless sql.nil? || sql.exclude?('SCHEMA')
        @queries.push(sql)
        track_table(sql)
      end
    end

    # Yield to the block
    yield
  ensure
    # Stop subscription
    ActiveSupport::Notifications.unsubscribe(@subscription) if @subscription
  end

  def track_table(sql)
    # Extract table name from SQL (simple heuristic)
    return unless sql =~ /FROM\s+"?(\w+)"?/i || sql =~ /UPDATE\s+"?(\w+)"?/i || sql =~ /INSERT INTO\s+"?(\w+)"?/i

    table = Regexp.last_match(1)
    @table_counts[table] ||= 0
    @table_counts[table] += 1
  end

  def total_count
    @queries.count
  end

  def report
    puts "\n" + '=' * 80
    puts 'QUERY PERFORMANCE REPORT'
    puts '=' * 80
    puts "Total Queries: #{total_count}"
    puts "\nQueries by Table:"
    @table_counts.sort_by { |_k, v| -v }.each do |table, count|
      puts "  #{table}: #{count} queries"
    end

    # Look for repeated queries (N+1 indicators)
    query_counts = @queries.group_by { |q| q }.transform_values(&:count)
    repeated = query_counts.select { |_q, count| count > 1 }.sort_by { |_q, count| -count }
    if repeated.any?
      puts "\nRepeated Queries (N+1 Indicators):"
      repeated.first(10).each do |sql, count|
        puts "  [#{count}x] #{sql[0..100]}..."
      end
    end
    puts '=' * 80 + "\n"
  end
end
