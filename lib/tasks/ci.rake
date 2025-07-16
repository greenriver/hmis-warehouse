# frozen_string_literal: true

require 'json'

#
# Rebalancing procedure:
# 1) run rspec with profiling enabled, output results to json. Maybe this should happen on every run but for now it requires manually changing the rails_tests.yml gh workflow so it invokes rspec with "--format json --out "tmp/rspec_profiles/rspec_results.json" --profile 100000"
# 2) download profiles from GH artifacts into rspec_profiles directory (manually finding the archive and downloading)
# 3) (optional) run `rails ci:profile_stats[rspec_profiles]` and review the results to assist with tuning, such as total buckets
# 4) run `rails ci:build_bucket_assignments[rspec_profiles]` which updates `.github/rspec_buckets.json` based on the rspec profiles
#
namespace :ci do
  desc 'Analyze rspec profiles, write bucket assignments to file'
  task :build_bucket_assignments, [:profile_dir, :buckets_file, :max_minutes] => :environment do |_t, args|
    profile_dir = args[:profile_dir] || 'rspec_profiles'
    buckets_file = args.buckets_file || Rails.root.join('.github/rspec_buckets.json')
    max_minutes = (args[:max_minutes] || 35).to_i

    unless Dir.exist?(profile_dir)
      puts "Profile dir '#{profile_dir}' not found."
      exit 1
    end

    # Load and process profile data
    profile_groups = load_profile_data(profile_dir)

    # Group specs by file_path and sum their times
    specs_by_file = profile_groups.group_by do |group|
      group[:location].split(':').first
    end.map do |file_path, groups|
      {
        file_path: file_path,
        total_time: groups.sum { |g| g[:total_time] },
        # carry original groups to be used in the buckets file
        groups: groups.map { |g| g.slice(:location, :total_time, :description) },
      }
    end

    # Filter out files that run for less than 10 seconds
    filtered_specs = specs_by_file.select { |spec_file| spec_file[:total_time] >= 10 }

    # Calculate total time and estimate number of buckets
    total_time = filtered_specs.sum { |spec| spec[:total_time] }
    estimated_buckets = (total_time / (max_minutes * 60.0)).ceil

    # Use bin packing algorithm to distribute specs
    buckets = bin_packing(filtered_specs, estimated_buckets)

    write_json_to_file(buckets, buckets_file)

    print_summary(buckets)
  end

  # WARNING: this modifies ruby source code to assign tags to specs.
  # After running this, you may need to update the matrix in rails_tests.yaml for new buckets
  # rails ci:update_spec_tags[/tmp/rspec_profiles/buckets.json]
  # profile information is generated from: rspec --format json --out rspec_results.json
  # or profile information cab be downloaded from gh actions archives
  desc 'Update RSpec test tags to match buckets file'
  task :update_spec_tags, [:buckets_file] => :environment do |_t, args|
    buckets_file = args.buckets_file || Rails.root.join('.github/rspec_buckets.json')

    unless File.exist?(buckets_file)
      puts "Buckets file '#{buckets_file}' not found."
      exit 1
    end

    buckets = read_json_from_file(buckets_file)
    buckets.map!(&:deep_symbolize_keys)
    update_source_files(buckets)
  end

  def load_profile_data(profile_dir)
    profile_groups = []
    Dir.glob(File.join(profile_dir, '*.json')) do |file_path|
      profile_data = JSON.parse(File.read(file_path), symbolize_names: true)
      profile_groups += profile_data[:profile][:groups]
    end
    profile_groups
  end

  def read_json_from_file(file_path)
    json_data = File.read(file_path)
    JSON.parse(json_data)
  end

  def write_json_to_file(json, file_path)
    File.open(file_path, 'w') do |file|
      file.write(JSON.pretty_generate(json))
    end
  end

  def bin_packing(specs, num_buckets)
    buckets = Array.new(num_buckets) { { id: nil, total_time: 0, specs: [] } }

    # Sort specs by total_time in descending order
    sorted_specs = specs.sort_by { |spec| -spec[:total_time] }

    sorted_specs.each do |spec|
      # Find the bucket with the least total time
      target_bucket = buckets.min_by { |bucket| bucket[:total_time] }

      # Add the spec to the target bucket
      target_bucket[:total_time] += spec[:total_time]
      target_bucket[:specs] << { file_path: spec[:file_path], total_time: spec[:total_time], groups: spec[:groups] }
    end

    # Assign IDs to non-empty buckets
    buckets.reject! { |bucket| bucket[:specs].empty? }
    buckets.each_with_index { |bucket, index| bucket[:id] = "bucket-#{index + 1}" }

    buckets
  end

  def update_source_files(buckets)
    buckets.each do |bucket|
      bucket[:specs].each do |spec|
        file_path = spec[:file_path]
        content = File.readlines(file_path)

        describe_line_index = content.index { |line| line.strip.start_with?('RSpec.describe') }

        if describe_line_index
          describe_line = content[describe_line_index]

          updated_line = if describe_line.include?('ci_bucket:')
            describe_line.gsub(/ci_bucket:\s*['"][\w\d-]+['"]/, "ci_bucket: '#{bucket[:id]}'")
          else
            parts = describe_line.rstrip.split(/\s*do\s*$/)
            "#{parts[0]}, ci_bucket: '#{bucket[:id]}' do#{parts[1]}\n"
          end

          content[describe_line_index] = updated_line
          File.write(file_path, content.join)
          puts "Updated #{file_path} with ci_bucket: '#{bucket[:id]}'"
        else
          puts "Could not find RSpec.describe line in #{file_path}"
        end
      end
    end
  end

  def print_summary(buckets)
    puts "Processed #{buckets.sum { |b| b[:specs].size }} test files across #{buckets.size} buckets."
    buckets.each do |bucket|
      minutes = (bucket[:total_time] / 60.0).round
      puts "#{bucket[:id]}: #{bucket[:specs].size} specs, total time: #{minutes} minutes"
    end
  end

  desc 'Analyze rspec profiles and print statistics'
  task :profile_stats, [:profile_dir, :top_n] => :environment do |_t, args|
    profile_dir = args[:profile_dir] || 'rspec_profiles'
    top_n = (args[:top_n] || 5).to_i

    unless Dir.exist?(profile_dir)
      puts "Profile dir '#{profile_dir}' not found."
      exit 1
    end

    all_groups = []
    Dir.glob(File.join(profile_dir, '*.json')).each do |file_path|
      profile_data = JSON.parse(File.read(file_path), symbolize_names: true)
      groups = profile_data.dig(:profile, :groups)
      next unless groups.is_a?(Array)

      all_groups.concat(groups)
    rescue JSON::ParserError
      puts "Warning: Skipping invalid JSON file: #{file_path}"
    end

    if all_groups.empty?
      puts "No spec groups found in #{profile_dir}."
      exit
    end

    all_times = all_groups.map { |g| g[:total_time] }.compact

    if all_times.empty?
      puts "No spec times found in #{profile_dir}."
      exit
    end

    # Group specs by file_path and sum their times
    specs_by_file = all_groups.group_by do |group|
      group[:location]&.split(':')&.first
    end.compact.transform_values do |groups|
      groups.sum { |g| g[:total_time] || 0 }
    end

    count = all_times.size
    sum = all_times.sum
    average = sum / count

    sorted_times = all_times.sort
    mid = count / 2
    median = count.odd? ? sorted_times[mid] : (sorted_times[mid - 1] + sorted_times[mid]) / 2.0

    puts 'RSpec Profile Stats'
    puts '-------------------'
    puts "Total spec groups processed: #{count}"
    puts "Average time per group: #{average.round(4)} seconds"
    puts "Median time per group:  #{median.round(4)} seconds"
    puts
    puts 'Distribution Analysis (by group count):'
    [0.5, 1, 2, 5, 10, 20, 30, 60].each do |cutoff|
      filtered_count = all_times.count { |t| t >= cutoff }
      percentage = (filtered_count.to_f / count * 100).round(2)
      puts "Groups >= #{cutoff}s:".ljust(15) + "#{filtered_count} (#{percentage}%)"
    end

    puts
    puts 'Worst Offenders (by file):'
    puts '--------------------------'
    sorted_specs_by_file = specs_by_file.sort_by { |_file, time| -time }
    sorted_specs_by_file.first(top_n).each do |file_path, total_time|
      puts "#{file_path.to_s.ljust(80)} #{total_time.round(2)}s"
    end
  end
end
