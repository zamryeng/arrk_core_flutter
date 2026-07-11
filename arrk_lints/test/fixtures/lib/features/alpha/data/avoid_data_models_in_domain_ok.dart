// OK: a file inside data/ may freely import its own data internals
// (models, sources, mappers). The rule only fires for importers OUTSIDE data/.
import 'models/alpha_model.dart';
import 'sources/alpha_source.dart';

class AlphaRepo {
  AlphaModel? model;
  AlphaSource? source;
}
