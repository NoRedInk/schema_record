module SchemaRecord
  class Context
    attr_accessor :full_schema, :cwd

    def initialize(file_path, root_path)
      fullpath = File.join root_path, file_path
      pathname = Pathname.new(fullpath)
      schema_string = pathname.read
      @full_schema = JSON.parse(schema_string)
      @cwd = pathname.realpath.dirname.to_s
    end
  end
end
