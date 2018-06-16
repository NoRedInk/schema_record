module SchemaRecord
  class Array
    def self.json_schema_hash(schema)
      case schema['type']
      when 'object'
        @record = Class.new(SchemaRecord::Base) do
          json_schema_hash schema
        end
      when 'array'
        @array = Class.new(SchemaRecord::Array) do
          json_schema_hash schema['items']
        end
      end
    end

    def self.initialize_item(item)
      if @record
        @record.new(item)
      elsif @array
        item.map do |nested_item|
          @array.initialize_item(nested_item)
        end
      else
        item
      end
    end
  end
end
