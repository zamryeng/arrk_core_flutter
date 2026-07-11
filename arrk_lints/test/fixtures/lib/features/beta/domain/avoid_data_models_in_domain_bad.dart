// expect_lint: avoid_data_models_in_domain
// A feature's domain/ importing ANOTHER feature's data/models is flagged — the
// data layer is a closed box; only the repo is part of its public surface.
import '../../alpha/data/models/alpha_model.dart';

class BetaConsumer {
  AlphaModel? model;
}
