require 'json'

module SchemaRecord
  class Base
    def initialize(**args)
      if additional_properties
        singleton_class.define_properties(args.keys)
        args.each do |prop, value|
          set_value(prop, value)
        end
      elsif pattern_properties.any?
        singleton_class.define_properties(properties)
        singleton_class.define_pattern_properties(
          args.keys.map(&:to_s),
          pattern_properties
        )
        properties.each do |prop|
          set_value(prop, args[prop.to_sym])
        end
      else
        properties.each do |prop|
          set_value(prop, args[prop.to_sym])
        end
      end
    end

    def self.json_schema_file(file_path)
      fullpath = File.join SchemaRecord.config.root_path, file_path
      schema_string = File.read(fullpath)
      schema = JSON.parse(schema_string)

      unless Array(schema['type']).include? 'object'
        raise InvalidSchemaError.new("top-level of json schema must be type: object")
      end

      json_schema_hash(schema, schema)
    end

    def self.json_schema_hash(schema, root_schema)
      # if schema['$ref']
      #   ref_schema = Reference.fetch_schema(schema['$ref'], root_schema)
      #   return json_schema_hash ref_schema, root_schema # todo: root_schema is the wrong context here
      # end

      @additional_properties = schema['additionalProperties'] != false

      props = schema['properties']

      if props.is_a?(Hash)
        define_properties(props.keys)
        props.each do |prop, spec|
          object_proc = -> (object) { nested_objects[prop] = object }
          array_proc  = -> (array ) {  nested_arrays[prop] = array  }

          process_schema(spec, root_schema, object_proc, array_proc)
        end
      end

      pattern_props = schema['patternProperties']

      if pattern_props.is_a?(Hash)
        @pattern_properties = pattern_props.keys
        pattern_props.each do |pattern, spec|
          object_proc = -> (object) {
            nested_objects_by_pattern[pattern] = object
          }
          array_proc = -> (array) {
            nested_arrays_by_pattern[pattern] = array
          }

          process_schema(spec, root_schema, object_proc, array_proc)
        end
      end
    end

    def self.process_schema(schema, root_schema, object_proc, array_proc)
      return unless schema.is_a?(Hash)

      if schema['$ref']
        ref_schema = Reference.fetch_schema(schema['$ref'], root_schema)
        return process_schema(ref_schema, root_schema, object_proc, array_proc) # todo: root_schema may not be the correct context
      end

      Array(schema['type']).each do |type|
        case type
        when 'object'
          object_proc.call(
            Class.new(SchemaRecord::Base) do
              json_schema_hash schema, root_schema
            end
          )
        when 'array'
          array_proc.call(
            Class.new(SchemaRecord::List) do
              json_schema_hash schema['items'], root_schema
            end
          )
        end
      end
    end

    def self.define_properties(props)
      @properties = props
      self.send :attr_reader, *props
    end

    def self.define_pattern_properties(props, patterns)
      props.each do |prop|
        if patterns.any? { |pattern| Regexp.new(pattern).match(prop) }
          properties << prop
          self.send :attr_reader, prop
        end
      end
    end

    def self.properties
      @properties ||= []
    end

    def properties
      self.class.properties
    end

    def self.additional_properties
      @additional_properties
    end

    def additional_properties
      self.class.additional_properties
    end

    def self.pattern_properties
      @pattern_properties ||= []
    end

    def pattern_properties
      self.class.pattern_properties
    end

    def self.nested_objects
      @nested_objects ||= {}
    end

    def nested_objects
      self.class.nested_objects
    end

    def self.nested_arrays
      @nested_arrays ||= {}
    end

    def nested_arrays
      self.class.nested_arrays
    end

    def self.nested_objects_by_pattern
      @nested_objects_by_pattern ||= {}
    end

    def nested_objects_by_pattern
      self.class.nested_objects_by_pattern
    end

    def self.nested_arrays_by_pattern
      @nested_arrays_by_pattern ||= {}
    end

    def nested_arrays_by_pattern
      self.class.nested_arrays_by_pattern
    end

    private
    def set_value(prop, arg)
      prop = prop.to_s
      value =
        case arg
        when Hash
          if nested_objects[prop]
            nested_objects[prop].new arg
          elsif record = matching_pattern(prop, nested_objects_by_pattern)
            record.new arg
          else
            arg
          end
        when Array
          if nested_arrays[prop]
            arg.map { |item| nested_arrays[prop].initialize_item item }
          elsif array_schema = matching_pattern(prop, nested_arrays_by_pattern)
            arg.map { |item| array_schema.initialize_item item }
          else
            arg
          end
        else
          arg
        end

      self.instance_variable_set("@#{prop}", value)
    end

    def matching_pattern(prop, patterns)
      patterns.each do |pattern, schema_obj|
        return schema_obj if Regexp.new(pattern).match(prop)
      end
      return nil
    end
  end
end
