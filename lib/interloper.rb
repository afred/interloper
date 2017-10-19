require "interloper/version"

module Interloper
  def before(*method_names, &callback)
    callback_layer_module.define_methods_with_hooks(*method_names)
    callback_layer_module.add_before_callbacks(*method_names, &callback)
  end

  def after(*method_names, &callback)
    callback_layer_module.define_methods_with_hooks(*method_names)
    callback_layer_module.add_after_callbacks(*method_names, &callback)
  end
end
