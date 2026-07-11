import 'package:arrk_core_flutter/navigation.dart';

import '../features/greeting/domain/dtos/greeting_draft_dto.dart';

/// The app's extras codec: one [ArrkExtraType] per Dto/args type that
/// crosses a route. Handed to `GoRouter(extraCodec:)` so flows survive web
/// history and deep-link round-trips.
final class ExampleExtrasCodec extends ArrkExtrasCodec {
  const ExampleExtrasCodec();

  @override
  List<ArrkExtraType<Object>> get types => [
    ArrkExtraType<GreetingDraftDto>(
      name: 'GreetingDraftDto',
      encode: (dto) => dto.toMap(),
      decode: (payload) => GreetingDraftDto.fromMap((payload! as Map).cast<String, dynamic>()),
    ),
  ];
}
