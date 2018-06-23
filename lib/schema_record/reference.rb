require 'json'

module SchemaRecord
  module Reference
    module_function
    def fetch_schema(path, context)
      file_path, _, property_path = path.partition('#')
      case file_path
      when ''
        [
          fetch_local_schema(property_path, context.full_schema),
          context
        ]
      else
        new_context = Context.new file_path, context.cwd
        [
          fetch_local_schema(property_path, new_context.full_schema),
          new_context
        ]
      end
    end

    private_class_method
    def fetch_local_schema(property_path, full_schema)
      properties = property_path.split('/')
      properties.shift if property_path[0] == '/'

      properties.reduce(full_schema) do |schema, prop|
        if schema && schema.has_key?(prop)
          schema[prop]
        else
          raise ArgumentError.new("Unable to find schema at $ref path <#{property_path}>")
        end
      end
    end
  end
end
