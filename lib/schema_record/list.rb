module SchemaRecord
  class List
    def self.json_schema_hash(schema, context)
      object_proc = -> (object) { @record = object }
      array_proc  = -> (array ) {  @array = array  }

      Base.process_schema(schema, context, object_proc, array_proc)
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
