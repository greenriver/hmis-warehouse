task dump_graphql_schema: :environment do
  # Replace 'MySchema' with your schema's Ruby class name.
  schema_definition = HmisSchema.to_definition
  schema_path = Rails.root.join('drivers', 'hmis', 'app', 'graphql', 'schema.graphql')
  File.write(schema_path, schema_definition)
  puts "Updated #{schema_path}"
end
