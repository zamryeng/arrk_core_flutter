// OK: domain/ importing the public repository class is allowed — only
// data/models, data/sources, data/mappers are off-limits from outside data/.
import '../data/alpha_repo.dart';

class AlphaService {
  AlphaRepository? repo;
}
