namespace :code do
  # NOTE, you can check a PR for this with
  # git diff -U0 --minimal HEAD~1 | grep -v '^+#.*2023' | grep -v '^+#.*LICENSE.md' | grep -v '^+###$' | grep -v '^+#$' | grep -v '^diff --git' | grep -v '^index' | grep '^--- a' | grep '^+++ b' | more
  desc 'Ensure the copyright is included in all ruby files'
  task :maintain_copyright, [] => [:environment, 'log:info_to_stdout'] do
    puts 'Adding license text in all .rb files that don\'t already have it'
    puts ::Code.copywright_header
    @modified = 0
    files.each do |path|
      add_copyright_to_file(path)
    end

    puts "Modified #{@modified} #{'record'.pluralize(@modified)}"
  end

  FN_NAME_OVERRIDES = {
    export_period_types: :period_types,
    no_yes_missings: :yes_no_missing_options,
    no_yes_reasons_for_missing_data: :no_yes_reasons_for_missing_data_options,
    name_data_qualities: :name_data_quality_options,
    ssn_data_qualities: :ssn_data_quality_options,
    dob_data_qualities: :dob_data_quality_options,
    residence_prior_length_of_stays: :length_of_stays,
    times_homeless_past_three_years: :times_homeless_options,
    months_homeless_past_three_years: :month_categories,
    relationship_to_ho_hs: :relationships_to_hoh,
    when_dv_occurreds: :when_occurreds,
    event_types: :events,
    dependent_under6s: :dependent_under_6,
  }.freeze
  LOOKUP_FN_OVERRIDES = {
    relationship_to_ho_h: :relationship_to_hoh,
    when_dv_occurred: :when_d_v_occurred,
    event_type: :event,
    dependent_under6: :dependent_under_6,
  }.freeze

  desc 'Generate HUD list mapping module'
  task generate_hud_lists: [:environment, 'log:info_to_stdout'] do
    filenames = []
    ['2022', '2024'].each do |year|
      source = File.read("lib/data/#{year}_hud_lists.json")
      all_lists = JSON.parse(source).sort_by { |hash| hash['code'] }
      skipped = []
      filename = "lib/util/concerns/hud_lists_#{year}.rb"
      filenames << filename
      arr = []
      arr.push ::Code.copywright_header
      arr.push "
        # frozen_string_literal: true
        # THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY
        module Concerns::HudLists#{year}
          extend ActiveSupport::Concern
            class_methods do
              def _translate(map, id, reverse)
                if reverse
                  rx = forgiving_regex id
                  if rx.is_a?(Regexp)
                    map.detect { |_, v| v.match?(rx) }.try(&:first)
                  else
                    map.detect { |_, v| v == rx }.try(&:first)
                  end
                else
                  map[id] || id
                end
              end
      "

      all_lists.each do |element|
        next if skipped.include?(element['code'].to_s)

        lookup_fn_name = element['name'].underscore
        map_name = lookup_fn_name.pluralize
        override = FN_NAME_OVERRIDES[map_name.to_sym]
        map_name = override.to_s if override.present?
        lookup_fn_name = LOOKUP_FN_OVERRIDES[lookup_fn_name.to_sym].to_s if LOOKUP_FN_OVERRIDES[lookup_fn_name.to_sym].present?

        map_values = element['values'].map do |obj|
          description = obj['description'].strip
          "#{obj['key'].to_json} => \"#{description}\""
        end.join(",\n")

        arr.push "
        # #{element['code']}
        def #{map_name}
          {\n#{map_values}\n}.freeze
        end

        def #{lookup_fn_name}(id, reverse = false)
          _translate #{map_name}, id, reverse
        end
        "
      end
      arr.push 'end'
      arr.push 'end'
      contents = arr.join("\n")
      File.open(filename, 'w') do |f|
        f.write(contents)
      end
    end
    exec("bundle exec rubocop -A --format simple #{filenames.join(' ')} > /dev/null")
  end

  def files
    Dir.glob("#{Rails.root}/app/{**/}*.rb") + Dir.glob("#{Rails.root}/drivers/{**/}*.rb")
  end

  def add_copyright_to_file path
    puts ">>> Prepending copyright to #{path}"
    @modified += 1
    lines = File.open(path).readlines
    if lines.slice(0, ::Code.copywright_header.lines.count).join == ::Code.copywright_header
      puts 'Found existing copyright, ignoring'
      @modified -= 1
    else
      tempfile = Tempfile.new('with_copyright')
      line = ''
      tempfile.write(::Code.copywright_header)
      tempfile.write(line)
      tempfile.write(lines.join)
      tempfile.flush
      tempfile.close
      FileUtils.cp(tempfile.path, path)
    end
  end
end
