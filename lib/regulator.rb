require "regulator/version"
require "regulator/policy_finder"
require "active_support/concern"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/module/introspection"
require "active_support/dependencies/autoload"

module Regulator
  SUFFIX = "Policy"

  class Error < StandardError; end
  class NotAuthorizedError < Error
    attr_reader :query, :record, :policy

    def initialize(options = {})
      if options.is_a? String
        message = options
      else
        @query  = options[:query]
        @record = options[:record]
        @policy = options[:policy]
        @controller_or_namespace = options[:controller_or_namespace]

        message = options.fetch(:message) { "not allowed to #{query} this #{record.inspect}" }
      end

      super(message)
    end
  end
  class AuthorizationNotPerformedError < Error; end
  class PolicyScopingNotPerformedError < AuthorizationNotPerformedError; end
  class NotDefinedError < Error; end

  extend ActiveSupport::Concern

  class << self
    def authorize(user, record, query, controller_or_namespace = nil)
      policy = policy!(user, record, controller_or_namespace)

      unless policy.public_send(query)
        raise NotAuthorizedError.new(query: query, record: record, policy: policy, controller_or_namespace: controller_or_namespace)
      end

      true
    end

    def policy_scope(user, scope, controller_or_namespace = nil)
      policy_scope = PolicyFinder.new(scope,controller_or_namespace).scope
      policy_scope.new(user, scope).resolve if policy_scope
    end

    def policy_scope!(user, scope, controller_or_namespace = nil)
      PolicyFinder.new(scope,controller_or_namespace).scope!.new(user, scope).resolve
    end

    def policy(user, record, controller_or_namespace = nil)
      policy = PolicyFinder.new(record,controller_or_namespace).policy
      policy.new(user, record) if policy
    end

    def policy!(user, record, controller_or_namespace = nil)
      PolicyFinder.new(record,controller_or_namespace).policy!.new(user, record)
    end
  end

  module Helper
    def policy_scope(scope)
      regulator_policy_scope(scope)
    end
  end

  included do
    def self.policy_namespace
      ( self.parent != Object ? self.parent : nil )
    end

    def policy_namespace
      @_policy_namespace ||= self.class.policy_namespace
    end

    helper Helper if respond_to?(:helper)
    if respond_to?(:helper_method)
      helper_method :policy
      helper_method :regulator_policy_scope
      helper_method :regulator_user
    end
    if respond_to?(:hide_action)
      hide_action :policy_namespace
      hide_action :policy
      hide_action :policy_scope
      hide_action :policies
      hide_action :policy_scopes
      hide_action :authorize
      hide_action :verify_authorized
      hide_action :verify_policy_scoped
      hide_action :permitted_attributes
      hide_action :regulator_user
      hide_action :skip_authorization
      hide_action :skip_policy_scope
      hide_action :regulator_policy_authorized?
      hide_action :regulator_policy_scoped?
    end
  end

  def regulator_policy_authorized?
    !!@_regulator_policy_authorized
  end

  def regulator_policy_scoped?
    !!@_regulator_policy_scoped
  end

  def verify_authorized
    raise AuthorizationNotPerformedError unless regulator_policy_authorized?
  end

  def verify_policy_scoped
    raise PolicyScopingNotPerformedError unless regulator_policy_scoped?
  end

  def authorize(record, query=nil)
    query ||= params[:action].to_s + "?"

    @_regulator_policy_authorized = true

    policy = policy(record)
    unless policy.public_send(query)
      raise NotAuthorizedError.new(query: query, record: record, policy: policy)
    end

    true
  end

  def skip_authorization
    @_regulator_policy_authorized = true
  end

  def skip_policy_scope
    @_regulator_policy_scoped = true
  end

  def policy_scope(scope)
    @_regulator_policy_scoped = true
    regulator_policy_scope(scope)
  end

  def policy(record)
    policies[record] ||= Regulator.policy!(regulator_user, record, self)
  end

  def permitted_attributes(record)
    name = record.class.to_s.demodulize.underscore
    params.require(name).permit(*policy(record).permitted_attributes)
  end

  def policies
    @_regulator_policies ||= {}
  end

  def policy_scopes
    @_regulator_policy_scopes ||= {}
  end

  def regulator_user
    current_user
  end
private

  def regulator_policy_scope(scope)
    policy_scopes[scope] ||= Regulator.policy_scope!(regulator_user, scope, self)
  end
end
