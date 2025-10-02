# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'puma_scaling_login_demand view' do
  let(:connection) { ActiveRecord::Base.connection }
  let(:db_now) do
    epoch = connection.select_value("SELECT EXTRACT(epoch FROM now() AT TIME ZONE 'UTC')")
    Time.at(epoch.to_f).utc
  end
  let(:start_of_current_hour) { db_now.beginning_of_hour }
  let(:window_start) { start_of_current_hour - 1.hour }
  let(:matching_day_offsets) do
    (1..30).select { |days| (db_now.to_date - days).wday == db_now.to_date.wday }
  end
  let(:matching_day_count) { matching_day_offsets.count }
  let(:window_duration_in_minutes) { 3 * 60 }

  before do
    LoginActivity.delete_all
  end

  # Returns the averaged metric as exposed by the database view.
  def fetch_average_distinct_logins
    connection.select_value('SELECT projected_unique_users FROM puma_scaling_login_demand').to_f
  end

  # Computes a timestamp within the historical 3-hour window for a given day offset.
  def historical_window_time(days_ago:, minutes_into_window: 0)
    window_start - days_ago.days + minutes_into_window.minutes
  end

  # Persists a login activity at the provided historical window time.
  def create_historical_login(user:, days_ago:, minutes_into_window: 0, success: true)
    create(
      :login_activity,
      user: user,
      created_at: historical_window_time(days_ago: days_ago, minutes_into_window: minutes_into_window),
      success: success,
    )
  end

  it 'returns zero when there are no matching day logins' do
    expect(fetch_average_distinct_logins).to eq(0.0)
  end

  it 'averages distinct logins across matching days' do
    counts = [2, 3, 1]

    matching_day_offsets.first(counts.length).zip(counts).each do |days_ago, count|
      create_list(:user, count).each_with_index do |user, index|
        create_historical_login(user: user, days_ago: days_ago, minutes_into_window: index * 10)
      end
    end

    expected_average = counts.sum.to_f / matching_day_count

    expect(fetch_average_distinct_logins).to be_within(0.0001).of(expected_average)
  end

  it 'counts each user at most once per day within the window' do
    day_offset = matching_day_offsets.first
    other_day_offset = matching_day_offsets.second

    user = create(:user)
    create_historical_login(user: user, days_ago: day_offset, minutes_into_window: 15)
    create_historical_login(user: user, days_ago: day_offset, minutes_into_window: 45)

    create_historical_login(user: create(:user), days_ago: other_day_offset, minutes_into_window: 30)

    expected_average = 2.0 / matching_day_count

    expect(fetch_average_distinct_logins).to be_within(0.0001).of(expected_average)
  end

  it 'ignores failed login attempts' do
    day_offset = matching_day_offsets.first

    create_historical_login(user: create(:user), days_ago: day_offset, minutes_into_window: 10)
    create_historical_login(user: create(:user), days_ago: day_offset, minutes_into_window: 20, success: false)

    expected_average = 1.0 / matching_day_count

    expect(fetch_average_distinct_logins).to be_within(0.0001).of(expected_average)
  end

  it 'ignores login activity outside the three-hour window' do
    day_offset = matching_day_offsets.first

    create_historical_login(user: create(:user), days_ago: day_offset, minutes_into_window: -5)
    create_historical_login(
      user: create(:user),
      days_ago: day_offset,
      minutes_into_window: window_duration_in_minutes + 5,
    )

    expect(fetch_average_distinct_logins).to eq(0.0)
  end

  it 'ignores login activity older than thirty days' do
    old_timestamp = window_start - 35.days + 10.minutes

    create(:login_activity, user: create(:user), created_at: old_timestamp, success: true)

    expect(fetch_average_distinct_logins).to eq(0.0)
  end

  it 'ignores login activity from non-matching days of the week' do
    create_historical_login(user: create(:user), days_ago: 1, minutes_into_window: 30)

    expect(fetch_average_distinct_logins).to eq(0.0)
  end
end
