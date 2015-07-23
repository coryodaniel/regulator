module Regulator
  module Generators
    class AdapterGenerator < ::Rails::Generators::Base
      source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

      def inject_into_file_require
        inject_into_file 'config/initializers/active_admin.rb', after: "ActiveAdmin.setup do |config|\n" do <<-'RUBY'
  require 'regulator_active_admin_adapter'
RUBY
end
      end

      def copy_regulator_active_admin_adapter
        # inject_into_file_require
        # inject_info_file_config_options
        template 'regulator_active_admin_adapter.rb', 'lib/regulator_active_admin_adapter.rb'
      end

      def inject_info_file_config_options
        inject_into_file 'config/initializers/active_admin.rb', after: "# == User Authentication\n" do <<-'RUBY'
  config.authorization_adapter = "ActiveAdmin::RegulatorAdapter"
  # Optional
  # Sets a scope for all ActiveAdmin polices to exist in
  #
  # Example
  # app/policies/admin_policies/user_policy.rb #=> AdminPolicies::UserPolicy
  #
  # config.regulator_policy_namespace = "AdminPolicies"
  config.regulator_policy_namespace = nil
  # Optional
  # Sets the default policy to use if no policy is found
  #
  # config.regulator_default_policy = BlackListPolicy
  config.regulator_default_policy = nil
RUBY

        end
      end
    end
  end
end
