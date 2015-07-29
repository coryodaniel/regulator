module Regulator
  class ActiveAdminAdapter < ActiveAdmin::AuthorizationAdapter
    def authorized?(action, subject = nil)
      policy = retrieve_policy(subject)
      action = format_action(action, subject)
      policy.respond_to?(action) && policy.public_send(action)
    end

    def scope_collection(collection, action = Auth::READ)
      # scoping is appliable only to read/index action
      # which means there is no way how to scope other actions
      Regulator.policy_scope!(user, collection, self.resource.controller)
    end

    def retrieve_policy(subject)
      case subject
      when nil   then Regulator.policy!(user, resource, self.resource.controller)
      when Class then Regulator.policy!(user, subject.new, self.resource.controller)
      else Regulator.policy!(user, subject, self.resource.controller)
      end
    end

    def format_action(action, subject)
      # https://github.com/elabs/regulator/blob/master/lib/generators/regulator/install/templates/application_policy.rb
      case action
      when ActiveAdmin::Auth::CREATE  then :create?
      when ActiveAdmin::Auth::UPDATE  then :update?
      when ActiveAdmin::Auth::READ    then subject.is_a?(Class) ? :index? : :show?
      when ActiveAdmin::Auth::DESTROY then subject.is_a?(Class) ? :destroy_all? : :destroy?
      else "#{action}?"
      end
    end
  end
end
