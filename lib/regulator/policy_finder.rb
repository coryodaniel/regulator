module Regulator
  class PolicyFinder
    attr_reader :object
    attr_reader :controller
    attr_reader :namespace

    def initialize(object, controller_or_namespace = nil)
      @object = object

      if controller_or_namespace.instance_of? Module
        # Its a Module
        @namespace = controller_or_namespace
      elsif controller_or_namespace.instance_of? Class
        # Controller Class
        @controller = controller_or_namespace

        # ActiveAdmin uses the Regulator API directly, it doesnt mix it into the controllers
        @namespace = if @controller.respond_to?(:policy_namespace)
          # if the controller explicitly sets the policy_namespace to we want to keep it nil
          @controller.try(:policy_namespace)
        else
          @controller.parent
        end
      elsif controller_or_namespace
        # Controller Instance
        @controller = controller_or_namespace

        # ActiveAdmin uses the Regulator API directly, it doesnt mix it into the controllers
        @namespace = if @controller.respond_to?(:policy_namespace)
          # if the controller explicitly sets the policy_namespace to we want to keep it nil
          @controller.try(:policy_namespace)
        else
          # Rails 6 renamed .parent to .module_parent
          if @controller.class.respond_to?(:module_parent)
            @controller.class.module_parent
          else
            @controller.class.parent
          end
        end
      end
    end

    def scope
      policy::Scope if policy
    rescue NameError
      nil
    end

    def policy
      klass = find
      klass = klass.constantize if klass.is_a?(String)
      klass
    rescue NameError
      nil
    end

    def scope!
      raise NotDefinedError, "unable to find policy scope of nil" if object.nil?
      scope or raise NotDefinedError, "unable to find scope `#{find}::Scope` for `#{object.inspect}`"
    end

    def policy!
      raise NotDefinedError, "unable to find policy of nil" if object.nil?
      policy or raise NotDefinedError, "unable to find policy `#{find}` for `#{object.inspect}`"
    end

  private

    def find
      if object.nil?
        nil
      elsif controller.respond_to?(:policy_class)
        controller.policy_class
      elsif controller.class.respond_to?(:policy_class)
        controller.class.policy_class
      elsif object.respond_to?(:policy_class)
        deprecation_warning("Model#policy_class", "User Controller#policy_class instead.")
        object.policy_class
      elsif object.class.respond_to?(:policy_class)
        deprecation_warning("Model.policy_class", "User Controller.policy_class instead.")
        object.class.policy_class
      else
        klass = if object.respond_to?(:model_name)
          object.model_name
        elsif object.class.respond_to?(:model_name)
          object.class.model_name
        elsif object.is_a?(Class)
          object
        elsif object.is_a?(Symbol)
          object.to_s.camelize
        elsif object.is_a?(Array)
          object.join('/').camelize
        else
          object.class
        end

        policy_name = "#{klass}#{SUFFIX}"

        namespace ? "#{namespace}::#{policy_name}" : policy_name
      end
    end

    def deprecation_warning(deprecated_method_name, message, caller_backtrace = nil)
       message = "#{deprecated_method_name} is deprecated and will be removed from Regulator | #{message}"
       Kernel.warn message
    end
  end
end
