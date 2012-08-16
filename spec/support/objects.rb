module Support
  module Objects
    extend ActiveSupport::Concern

    module ClassMethods
      def uses_objects(*objects)
        before { create_objects(*objects) }
      end
    end

    def create_objects(*objects)
      objects.each { |object| create_object(object) }
    end

    def remove_objects(*objects)
      objects.each { |object| remove_object(object) }
    end

    def create_object(object)
      remove_object(object)
      Object.const_set(object, Object(object))
    end

    def remove_object(object)
      Object.send(:remove_const, object) if Kernel.const_defined?(object)
    end

    def Object(name=nil)
      Class.new.tap do |object|
        object.class_eval "" "
          include Toy::Object
          attribute :name, String
        " "" if name
      end
    end
  end
end