// OK: a service-layer file (`lib/services/`) may import a feature's data/
// internals. Data-access backends legitimately convert wire/database formats
// to domain types at the boundary, so the rule exempts `lib/services/`.
// Importing data/models, data/sources, and data/mappers is allowed here; only
// domain/UI are restricted (see beta/domain/avoid_data_models_in_domain_bad.dart).
import '../../features/alpha/data/models/alpha_model.dart';

class AlphaDatabaseBackend {
  AlphaModel? row;
}
