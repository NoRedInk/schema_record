module SchemaRecord
  class List
    def self.json_schema_hash(schema, root_schema)
      return unless schema.is_a?(Hash)

      # while schema['$ref']
      #   schema = Reference.fetch_schema(schema['$ref'], root_schema) # todo: root_schema is the wrong context here
      # end

      Array(schema['type']).each do |type|
        case type
        when 'object'
          @record = Class.new(SchemaRecord::Base) do
            json_schema_hash schema, root_schema
          end
        when 'array'
          @array = Class.new(SchemaRecord::List) do
            json_schema_hash schema['items'], root_schema
          end
        end
      end
    end

    def self.initialize_item(item)
      if item.is_a?(Hash) && @record
        @record.new(item)
      elsif item.is_a?(Array) && @array
        item.map do |nested_item|
          @array.initialize_item(nested_item)
        end
      else
        item
      end
    end
  end
end
