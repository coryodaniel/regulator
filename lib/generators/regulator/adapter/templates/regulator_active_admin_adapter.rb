ActiveAdmin::Dependency.regulator!

require 'regulator'

# Add a setting to the application to configure the regulator default policy
ActiveAdmin::Application.inheritable_setting :regulator_default_policy, nil

# policy_namespace will default to ActiveAdmin, override it here
ActiveAdmin::Application.inheritable_setting :regulator_policy_namespace, nil

module ActiveAdmin
  class RegulatorAdapter < AuthorizationAdapter

    def authorized?(action, subject = nil)
      policy = retrieve_policy(subject)
      action = format_action(action, subject)

      policy.respond_to?(action) && policy.public_send(action)
    end

    def scope_collection(collection, action = Auth::READ)
      # scoping is appliable only to read/index action
      # which means there is no way how to scope other actions
      Regulator.policy_scope!(user, collection, regulator_policy_namespace)
    rescue Regulator::NotDefinedError => e
      if default_policy_class && default_policy_class.const_defined?(:Scope)
        default_policy_class::Scope.new(user, collection).resolve
      else
        raise e
      end
    end

    def retrieve_policy(subject)
      case subject
      when nil   then Regulator.policy!(user, resource, regulator_policy_namespace)
      when Class then Regulator.policy!(user, subject.new, regulator_policy_namespace)
      else Regulator.policy!(user, subject, regulator_policy_namespace)
      end
    rescue Regulator::NotDefinedError => e
      if default_policy_class
        default_policy(user, subject)
      else
        raise e
      end
    end

    def format_action(action, subject)
      # https://github.com/elabs/regulator/blob/master/lib/generators/regulator/install/templates/application_policy.rb
      case action
      when Auth::CREATE  then :create?
      when Auth::UPDATE  then :update?
      when Auth::READ    then subject.is_a?(Class) ? :index? : :show?
      when Auth::DESTROY then subject.is_a?(Class) ? :destroy_all? : :destroy?
      else "#{action}?"
      end
    end

    private

    def regulator_policy_namespace
      ActiveAdmin.application.regulator_policy_namespace && ActiveAdmin.application.regulator_policy_namespace.constantize
    end

    def default_policy_class
      ActiveAdmin.application.regulator_default_policy && ActiveAdmin.application.regulator_default_policy.constantize
    end

    def default_policy(user, subject)
      default_policy_class.new(user, subject)
    end

  end

end
