import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/rules/avoid_data_models_in_domain.dart';
import 'src/rules/capability_stateless.dart';
import 'src/rules/event_bus_publisher_restriction.dart';
import 'src/rules/event_naming_past_tense.dart';
import 'src/rules/event_subscribe_restriction.dart';
import 'src/rules/message_stream_restriction.dart';
import 'src/rules/no_build_context_in_domain_or_data_or_services.dart';
import 'src/rules/no_change_notifier_outside_vm.dart';
import 'src/rules/no_cross_repo_calls.dart';
import 'src/rules/no_event_bus_in_repo.dart';
import 'src/rules/no_event_fire_in_handler.dart';
import 'src/rules/no_manager_in_features.dart';
import 'src/rules/no_repo_interfaces.dart';
import 'src/rules/no_service_locator_in_features.dart';
import 'src/rules/no_singleton_viewmodel.dart';
import 'src/rules/no_try_catch_in_domain.dart';
import 'src/rules/subscription_cancelled_in_dispose.dart';
import 'src/rules/vm_uses_capabilities_only.dart';

/// Entry point for the arrk architecture lint plugin.
///
/// Enabled from the consuming product's `analysis_options.yaml`:
/// ```yaml
/// plugins:
///   arrk_lints:
///     git:
///       url: <your arrk_core_flutter git URL>
///       ref: v0.1.1
///       path: arrk_lints
///     diagnostics:
///       no_manager_in_features: true
///       # ... one entry per rule
/// ```
///
/// Rules run inside `dart analyze`, `flutter analyze`, and the IDE. NOTE:
/// plugin diagnostics only surface for explicitly-listed file arguments — not
/// whole-directory analysis (`dart analyze <dir>` / `flutter analyze` scanning
/// the project show nothing). Explicit per-file args work under both
/// `dart analyze <file>` and `flutter analyze <file>`. CI enumerates files;
/// see run.sh.
final plugin = ArrkLintsPlugin();

class ArrkLintsPlugin extends Plugin {
  @override
  String get name => 'arrk_lints';

  @override
  void register(PluginRegistry registry) {
    registry.registerLintRule(AvoidDataModelsInDomain());
    registry.registerLintRule(CapabilityStateless());
    registry.registerLintRule(EventBusPublisherRestriction());
    registry.registerLintRule(EventNamingPastTense());
    registry.registerLintRule(EventSubscribeRestriction());
    registry.registerLintRule(MessageStreamRestriction());
    registry.registerLintRule(NoBuildContextInDomainOrDataOrServices());
    registry.registerLintRule(NoChangeNotifierOutsideVm());
    registry.registerLintRule(NoCrossRepoCalls());
    registry.registerLintRule(NoEventBusInRepo());
    registry.registerLintRule(NoEventFireInHandler());
    registry.registerLintRule(NoManagerInFeatures());
    registry.registerLintRule(NoRepoInterfaces());
    registry.registerLintRule(NoServiceLocatorInFeatures());
    registry.registerLintRule(NoSingletonViewModel());
    registry.registerLintRule(NoTryCatchInDomain());
    registry.registerLintRule(SubscriptionCancelledInDispose());
    registry.registerLintRule(VmUsesCapabilitiesOnly());
  }
}
