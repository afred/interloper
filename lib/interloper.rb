require "interloper/version"

module Interloper

  def interloper_module
    self.class.interloper_module
  end

  def Interloper.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    # Generates an Interloper module that is namespeced under the including
    # class, if one does not already exist. Then prepends the Interloper
    # module to the including class.
    # @return Module the Interloper module that was prepended to the including
    #   class.
    def interloper_module
      # Create the Interloper module if it doesn't exist already
      const_set(:Interloper, generate_interloper_module) unless self.constants.include? :Interloper
      # Prepend the interloper module
      prepend const_get(:Interloper)
      const_get(:Interloper)
    end

    def generate_interloper_module
      Module.new do
        class << self
          def before_callbacks
            @before_callbacks ||= {}
          end

          def after_callbacks
            @after_callbacks ||= {}
          end

          def before_callbacks_for(method_name)
            before_callbacks[method_name] || []
          end

          def after_callbacks_for(method_name)
            after_callbacks[method_name] || []
          end

          def run_all_before_callbacks_for(method_name, object_context, *orig_args, &orig_block)
            before_callbacks_for(method_name).each do |callback|
              # object_context.instance_eval(callback.call(*orig_args,&orig_block))
              object_context.instance_eval &callback
            end
          end

          def run_all_after_callbacks_for(method_name, object_context, *orig_args, &orig_block)
            after_callbacks_for(method_name).each do |callback|
              object_context.instance_eval(callback.call(*orig_args,&orig_block))
            end
          end


          def add_before_callbacks(*method_names, &callback)
            method_names.each do |method_name|
              before_callbacks[method_name] ||= []
              before_callbacks[method_name] << callback
            end
          end

          def add_after_callbacks(*method_names, &callback)
            method_names.each do |method_name|
              after_callbacks[method_name] ||= []
              after_callbacks[method_name] << callback
            end
          end

          def define_interloper_methods(*method_names)
            method_names.each do |method_name|
              define_method(method_name) do |*args, &block|
                called_method = __method__
                interloper_module.run_all_before_callbacks_for(called_method, self, *args, &block)
                return_val = super(*args,&block)
                interloper_module.run_all_after_callbacks_for(called_method, self, *args, &block)
                return_val
              end
            end
          end
        end
      end
    end

    def before(*method_names, &callback)
      interloper_module.define_interloper_methods(*method_names)
      interloper_module.add_before_callbacks(*method_names, &callback)
    end

    def after(*method_names, &callback)
      interloper_module.define_interloper_methods(*method_names)
      interloper_module.add_after_callbacks(*method_names, &callback)
    end
  end
end
