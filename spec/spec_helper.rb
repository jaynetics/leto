require "leto"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
end

def deep_object
  @deep_object ||=
    [
      {
        "KEY1" => struct_class.new("a".."z").tap do |struct|
          struct.instance_variable_set(
            :@ivar,
            [
              {
                DEEP_KEY: "DEEP STUFF!",
              },
              struct_class
            ]
          )
        end
      }
    ]
end

def struct_class
  @struct_class ||= begin
    klass = Struct.new(:foo)
    klass.const_set(:CONSTANT, 'CONSTANT')
    klass.class_variable_set(:@@cv, 'cv') # rubocop:disable Style/ClassVars
    klass
  end
end
