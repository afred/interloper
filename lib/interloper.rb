require "interloper/version"

module Interloper

  def interloper_module
    @interloper_module ||= self.class.interloper_module
  end

  def Interloper.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def interloper_const_name
      if self.name
        "Interloper"
      else
        "AnonymousInterloper#{self.object_id}"
      end.to_sym
    end

    # Generates an Interloper module that is namespaced under the including
    # class, if one does not already exist. Then prepends the Interloper
    # module to the including class.
    # @return Module the Interloper module that was prepended to the including
    #   class.
    def interloper_module
      unless self.constants.include? interloper_const_name
        const_set(interloper_const_name, generate_interloper_module)
        prepend const_get(interloper_const_name)
      end
      const_get(interloper_const_name)
    end

    def generate_interloper_module
      Module.new do
        class << self
          # @return [Array] The list of available hooks.
          def hooks
            [:before, :after]
          end

          # @return [Hash] The default hash for tracking callbacks to methods.
          def default_callbacks
            {}.tap do |callbacks|
              hooks.each do |hook|
                callbacks[hook] = {}
              end
            end
          end

          # @param [Symbol] hook Optional name of a hook. See .hook method in
          #   this module.
          # @param [Symbol] method_name Optional name of a method.
          # @return [Hash, Array] A hash or array of callbacks. If the 'hook'
          #   param is provided, it will return a hash of callbacks keyed by
          #   method name. If both 'hook' and 'method_name' are provided, will
          #   return an array of callbacks for the given hook and method.
          def callbacks(hook=nil, method_name=nil)
            @callbacks ||= default_callbacks
            if hook && method_name
              # Returns callback stack for a given method and hook. If there
              # aren't callbacks in the stack, return something enumberable to
              # be loop-friendly.
              @callbacks.fetch(hook).fetch(method_name, [])
            elsif hook
              # Return all callbacks for a given hook, e.g. :before.
              @callbacks.fetch(hook)
            else
              @callbacks
            end
          end

          def run_callbacks(hook, method_name, object_context, *orig_args, &orig_block)
            callbacks(hook, method_name).each do |callback|
              object_context.instance_exec *orig_args, &callback
            end
          end

          def add_callbacks(hook, *method_names, &callback)
            method_names.each do |method_name|
              callbacks[hook][method_name] ||= []
              callbacks[hook][method_name] << callback
            end
          end

          def define_interloper_methods(*method_names, interloper_module_name)
            method_names.each do |method_name|
              unless instance_methods.include? method_name
                module_eval do
                  eval <<-CODE
                    def #{method_name}(*args, &block)
                      self.class.const_get(:#{interloper_module_name}).run_callbacks(:before, :#{method_name}, self, *args, &block)
                      super(*args, &block)
                      self.class.const_get(:#{interloper_module_name}).run_callbacks(:after, :#{method_name}, self, *args, &block)
                    end
                  CODE
                end
              end
            end
          end
        end
      end
    end

    def before(*method_names, &callback)
      interloper_module.define_interloper_methods(*method_names, interloper_const_name)
      interloper_module.add_callbacks(:before, *method_names, &callback)
    end

    def after(*method_names, &callback)
      interloper_module.define_interloper_methods(*method_names, interloper_const_name)
      interloper_module.add_callbacks(:after, *method_names, &callback)
    end
  end
end
