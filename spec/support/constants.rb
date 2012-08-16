module Support
  module Constants
    extend ActiveSupport::Concern

    if ActiveSupport::VERSION::MAJOR == 3 && ActiveSupport::VERSION::MINOR > 1 # ActiveSupport 3.2
      included do
        class_eval do
          def self.uses_constants(*constants)
            before { create_constants *constants }
            after { remove_constants *constants }
          end
        end
      end
    else # ActiveSupport 3.0, 3.1
      module ClassMethods
        def uses_constants(*constants)
          before { create_constants *constants }
          after { remove_constants *constants }
        end
      end
    end

    def create_constants(*constants)
      constants.each { |constant| create_constant constant }
    end

    def remove_constants(*constants)
      constants.each { |constant| remove_constant constant }
    end

    def create_constant(constant, superclass=nil)
      remove_constant(constant)
      Object.const_set constant, Model(superclass)
    end

    def remove_constant(constant)
      if Object.const_defined?(constant)
        Object.send :remove_const, constant
      end
    end

    def Model(superclass=nil)
      if superclass.nil?
        Class.new { include Toy::Store }
      else
        Class.new(superclass) { include Toy::Store }
      end
    end
  end
end
