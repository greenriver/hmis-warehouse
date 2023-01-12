require 'digest/sha1'

desc 'Update schema.graphql dump'
task dump_graphql_schema: [:environment, 'log:info_to_stdout'] do
  schema_definition = HmisSchema.to_definition
  schema_path = Rails.root.join('drivers', 'hmis', 'app', 'graphql', 'schema.graphql')

  old_sha = Digest::SHA1.hexdigest(File.read(schema_path))

  File.write(schema_path, schema_definition)

  new_sha = Digest::SHA1.hexdigest(File.read(schema_path))
  if old_sha != new_sha
    # Use 'abort' to exit with status code 1, to indicate that the schema has changed
    abort "Updated #{schema_path}"
  else
    puts 'Schema unchanged.'
  end
end

desc 'Generate GraphQL Enums'
task generate_graphql_enums: [:environment, 'log:info_to_stdout'] do
  source = File.read('lib/data/hud_lists.json')
  skipped = ['race', '3.6.1', '2.4.2', '1.6']
  filename = 'drivers/hmis/app/graphql/types/hmis_schema/enums/hud.rb'

  seen = []
  arr = []
  arr.push ::Code.copywright_header
  arr.push "# frozen_string_literal: true\n"
  arr.push "# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY\n"
  arr.push 'module Types::HmisSchema::Enums::Hud'
  JSON.parse(source).each do |element|
    next if skipped.include?(element['code'].to_s)

    name = element['name']
    next if seen.include?(name)

    arr.push "  class #{name} < Types::BaseEnum"
    arr.push "    description '#{element['code'] || name}'"
    arr.push "    graphql_name '#{name}'"
    arr.push "    hud_enum ::HudLists.#{name.underscore}_map"
    arr.push '  end'
    seen << name
  end

  arr.push 'end'
  contents = arr.join("\n")
  File.open(filename, 'w') do |f|
    f.write(contents)
  end
  exec("bundle exec rubocop -A --format simple #{filename}")
end
