
require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::SyncAnalysisDataTask do
  let(:task) { described_class.new }
  let(:connection) { GrdaWarehouseBase.connection }

  it 'exports users to analytics.app_users' do
    user = create(:user, first_name: 'Alice', last_name: 'Smith', email: 'alice@example.com')

    expect {
      task.perform
    }.to change {
      connection.exec_query("SELECT COUNT(*) FROM analytics.app_users").first['count']
    }.from(0).to(1)

    exported = connection.exec_query("SELECT * FROM analytics.app_users WHERE id = #{user.id}").first

    expect(exported['first_name']).to eq('Alice')
    expect(exported['last_name']).to eq('Smith')
    expect(exported['email']).to eq('alice@example.com')
  end

  it 'updates existing records on conflict' do
    user = create(:user, first_name: 'Bob', last_name: 'Jones', email: 'bob@example.com')

    # Seed the analytics table with an outdated version
    connection.execute(<<~SQL)
      INSERT INTO analytics.app_users (id, first_name, last_name, email)
      VALUES (#{user.id}, 'Old', 'Name', 'old@example.com')
    SQL

    # Run the sync
    task.perform

    exported = connection.exec_query("SELECT * FROM analytics.app_users WHERE id = #{user.id}").first

    expect(exported['first_name']).to eq('Bob')
    expect(exported['last_name']).to eq('Jones')
    expect(exported['email']).to eq('bob@example.com')
  end
end
