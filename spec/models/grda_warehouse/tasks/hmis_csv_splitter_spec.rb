###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::HmisCsvSplitter do
  let(:source_path) { Dir.mktmpdir('splitter-source') }
  let(:destination_path) { Dir.mktmpdir('splitter-dest') }

  after do
    FileUtils.rm_rf(source_path)
    FileUtils.rm_rf(destination_path)
  end

  def write_csv(dir, filename, headers, rows)
    CSV.open(File.join(dir, filename), 'wb') do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
  end

  def read_column(path, column)
    CSV.read(path, headers: true).map { |row| row[column] }
  end

  describe '.balance_projects' do
    it 'isolates a dominant project and pairs the remaining projects across the other parts' do
      counts = { 'P1' => 75, 'P2' => 6, 'P3' => 6, 'P4' => 7, 'P5' => 6 }

      groups = described_class.balance_projects(counts, 3)

      expect(groups.size).to eq(3)
      expect(groups).to include(['P1'])
      small_groups = groups.reject { |g| g == ['P1'] }
      expect(small_groups.map(&:size)).to eq([2, 2])
      expect(small_groups.flatten).to contain_exactly('P2', 'P3', 'P4', 'P5')
    end

    it 'assigns each project to the part with the smallest running enrollment total' do
      counts = { 'A' => 10, 'B' => 8, 'C' => 7, 'D' => 5 }

      groups = described_class.balance_projects(counts, 2)

      # LPT order: A->part1 (10), B->part2 (8), C->part2 (15), D->part1 (15)
      expect(groups).to eq([['A', 'D'], ['B', 'C']])
    end

    it 'places projects with zero enrollments into the part with the smallest total' do
      counts = { 'BIG' => 20, 'Z1' => 0, 'Z2' => 0 }

      groups = described_class.balance_projects(counts, 2)

      expect(groups).to eq([['BIG'], ['Z1', 'Z2']])
    end

    it 'returns exactly the requested number of parts, leaving later parts empty when projects run out' do
      groups = described_class.balance_projects({ 'P1' => 3 }, 3)

      expect(groups).to eq([['P1'], [], []])
    end

    it 'breaks ties by project id so the grouping is deterministic regardless of hash order' do
      forward = described_class.balance_projects({ 'X' => 5, 'Y' => 5, 'W' => 5 }, 2)
      reversed = described_class.balance_projects({ 'W' => 5, 'Y' => 5, 'X' => 5 }, 2)

      expect(forward).to eq([['W', 'Y'], ['X']])
      expect(reversed).to eq(forward)
    end
  end

  describe '.project_enrollment_counts' do
    it 'counts enrollments per ProjectID, including zero for projects with none and projects only seen in Enrollment.csv' do
      projects = [
        ['P1', 'O1', 'One'],
        ['P2', 'O1', 'Two'],
        ['EMPTY', 'O2', 'No enrollments'],
      ]
      enrollments = [
        ['E1', 'C1', 'P1'],
        ['E2', 'C2', 'P1'],
        ['E3', 'C3', 'P2'],
        ['E4', 'C4', 'ORPHAN'],
      ]
      write_csv(source_path, 'Project.csv', ['ProjectID', 'OrganizationID', 'ProjectName'], projects)
      write_csv(source_path, 'Enrollment.csv', ['EnrollmentID', 'PersonalID', 'ProjectID'], enrollments)

      counts = described_class.project_enrollment_counts(source_path)

      expect(counts).to eq('P1' => 2, 'P2' => 1, 'EMPTY' => 0, 'ORPHAN' => 1)
    end
  end

  describe '.split_evenly' do
    # 6 projects: P1 holds 12 of 16 enrollments, P2..P5 hold 1 each, P6 has none.
    # Expected grouping for 3 parts: [P1], [P2, P4, P6], [P3, P5].
    let(:projects) do
      [['P1', 'O1'], ['P2', 'O1'], ['P3', 'O2'], ['P4', 'O2'], ['P5', 'O2'], ['P6', 'O3']]
    end
    let(:enrollments) do
      p1 = (1..12).map { |i| ["E1-#{i}", "C1-#{i}", 'P1'] }
      p1 + [['E2', 'C2', 'P2'], ['E3', 'C3', 'P3'], ['E4', 'C4', 'P4'], ['E5', 'C5', 'P5']]
    end
    let(:enrolled_client_ids) { enrollments.map { |row| row[1] } }

    before do
      write_csv(source_path, 'Export.csv', ['ExportID', 'SourceType'], [['EX1', '3']])
      write_csv(source_path, 'User.csv', ['UserID', 'UserFirstName'], [['U1', 'Pat']])
      write_csv(source_path, 'Organization.csv', ['OrganizationID', 'OrganizationName'], [['O1', 'One'], ['O2', 'Two'], ['O3', 'Three']])
      write_csv(source_path, 'Project.csv', ['ProjectID', 'OrganizationID', 'ProjectName'], projects.map { |id, org| [id, org, id] })
      write_csv(source_path, 'Enrollment.csv', ['EnrollmentID', 'PersonalID', 'ProjectID'], enrollments)
      write_csv(source_path, 'Client.csv', ['PersonalID', 'FirstName'], (enrolled_client_ids + ['UNENROLLED']).map { |id| [id, id] })
      write_csv(source_path, 'Exit.csv', ['ExitID', 'EnrollmentID', 'PersonalID'], enrollments.map { |e, c, _| ["X-#{e}", e, c] })
    end

    def part_dir(index)
      File.join(destination_path, "part_#{index}")
    end

    it 'writes one directory per part with the dominant project alone and the rest balanced' do
      described_class.split_evenly(source_path: source_path, destination_path: destination_path, parts: 3)

      expect(Dir.children(destination_path)).to contain_exactly('part_1', 'part_2', 'part_3')
      expect(read_column(File.join(part_dir(1), 'Project.csv'), 'ProjectID')).to contain_exactly('P1')
      expect(read_column(File.join(part_dir(2), 'Project.csv'), 'ProjectID')).to contain_exactly('P2', 'P4', 'P6')
      expect(read_column(File.join(part_dir(3), 'Project.csv'), 'ProjectID')).to contain_exactly('P3', 'P5')
    end

    it 'partitions enrollment-scoped rows so every source row appears in exactly one part' do
      described_class.split_evenly(source_path: source_path, destination_path: destination_path, parts: 3)

      enrollment_ids_by_part = (1..3).map { |i| read_column(File.join(part_dir(i), 'Enrollment.csv'), 'EnrollmentID') }
      exit_ids_by_part = (1..3).map { |i| read_column(File.join(part_dir(i), 'Exit.csv'), 'EnrollmentID') }

      expect(enrollment_ids_by_part.flatten).to contain_exactly(*enrollments.map(&:first))
      expect(enrollment_ids_by_part.map(&:size)).to eq([12, 2, 2])
      expect(exit_ids_by_part).to eq(enrollment_ids_by_part)
    end

    it 'limits Organization.csv in each part to the organizations of that part\'s projects' do
      described_class.split_evenly(source_path: source_path, destination_path: destination_path, parts: 3)

      expect(read_column(File.join(part_dir(1), 'Organization.csv'), 'OrganizationID')).to contain_exactly('O1')
      expect(read_column(File.join(part_dir(2), 'Organization.csv'), 'OrganizationID')).to contain_exactly('O1', 'O2', 'O3')
      expect(read_column(File.join(part_dir(3), 'Organization.csv'), 'OrganizationID')).to contain_exactly('O2')
    end

    it 'copies Export.csv and User.csv unchanged into every part' do
      described_class.split_evenly(source_path: source_path, destination_path: destination_path, parts: 3)

      (1..3).each do |i|
        expect(File.read(File.join(part_dir(i), 'Export.csv'))).to eq(File.read(File.join(source_path, 'Export.csv')))
        expect(File.read(File.join(part_dir(i), 'User.csv'))).to eq(File.read(File.join(source_path, 'User.csv')))
      end
    end

    it 'excludes unenrolled clients from every part by default' do
      described_class.split_evenly(source_path: source_path, destination_path: destination_path, parts: 3)

      client_ids_by_part = (1..3).map { |i| read_column(File.join(part_dir(i), 'Client.csv'), 'PersonalID') }

      expect(client_ids_by_part.flatten).to contain_exactly(*enrolled_client_ids)
    end

    it 'adds unenrolled clients to part 1 only when include_unenrolled_clients is true' do
      described_class.split_evenly(source_path: source_path, destination_path: destination_path, parts: 3, include_unenrolled_clients: true)

      client_ids_by_part = (1..3).map { |i| read_column(File.join(part_dir(i), 'Client.csv'), 'PersonalID') }

      expect(client_ids_by_part[0]).to include('UNENROLLED')
      expect(client_ids_by_part[1]).not_to include('UNENROLLED')
      expect(client_ids_by_part[2]).not_to include('UNENROLLED')
      expect(client_ids_by_part.flatten).to contain_exactly(*enrolled_client_ids, 'UNENROLLED')
    end

    it 'returns one run splitter per part so results can be reconciled against the source' do
      splitters = described_class.split_evenly(source_path: source_path, destination_path: destination_path, parts: 3)

      expect(splitters.map(&:project_ids)).to eq([['P1'], ['P2', 'P4', 'P6'], ['P3', 'P5']])
      added = splitters.sum { |s| s.results['Enrollment.csv'][:added] }
      expect(added).to eq(enrollments.size)
      expect(splitters.first.results['Enrollment.csv'][:original]).to eq(enrollments.size)
    end

    it 'raises ArgumentError when parts is not a positive integer' do
      expect { described_class.split_evenly(source_path: source_path, destination_path: destination_path, parts: 0) }.
        to raise_error(ArgumentError, /parts/)
      expect { described_class.split_evenly(source_path: source_path, destination_path: destination_path, parts: '3') }.
        to raise_error(ArgumentError, /parts/)
    end
  end
end
