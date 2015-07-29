# Regulator

## 0.1.3 (2015-07-29)
- made Regulator::PolicyFinder.new a bit more nimble
- included a simple activeadmin adapter that can be 'required' instead of generated

## 0.1.2 (2015-07-23)
- Add generators for install, policy, and activeadmin adapter

## 0.1.1 (2015-07-23)
- Regulator.authorize support for controller namespacing
- Regulator can accept a controller instance or an explicity modules name
  - Regulator.policy!(user,resource, my_controller_instance)
  - Regulator.policy!(user,resource, Api::V2)

## 0.1.0 (2015-07-23)
- initial release
- pundit compatible
- controller based policy namespacing
ActiveAdmin.application.regulator_policy_namespace
