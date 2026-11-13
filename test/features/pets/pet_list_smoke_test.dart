import 'package:bloc_test/bloc_test.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/features/pets/presentation/widgets/pet_list_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockPetBloc extends MockBloc<PetEvent, PetState> implements PetBloc {}

void main() {
  Future<void> pump(WidgetTester tester, PetState state, Widget page) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bloc = _MockPetBloc();
    whenListen(bloc, const Stream<PetState>.empty(), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.6),
          ),
          child: child!,
        ),
        home: BlocProvider<PetBloc>.value(value: bloc, child: page),
      ),
    );
    await tester.pump();
  }

  final pet = Pet(
    id: 1,
    ownerId: 2,
    name: 'A very long pet name that should be cut off safely',
    species: PetSpecies.dog,
    breed: 'Long breed name Retriever Mix Special',
    weightKg: 25.5,
    birthDate: DateTime(2020, 1, 1),
    microchipId: '123',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  testWidgets('owner list with pets does not overflow', (tester) async {
    await pump(tester, PetsLoaded([pet]), const PetListView(ownerId: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('staff list with pets does not overflow', (tester) async {
    await pump(tester, PetsLoaded([pet]), const StaffPetListView());
    expect(tester.takeException(), isNull);
  });

  testWidgets('owner list empty state does not overflow', (tester) async {
    await pump(tester, const PetsLoaded([]), const PetListView(ownerId: 2));
    expect(tester.takeException(), isNull);
  });
}
