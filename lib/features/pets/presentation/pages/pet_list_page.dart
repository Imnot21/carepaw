import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/pets/presentation/widgets/pet_list_widgets.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';

/// Page showing the list of user's pets with the CarePaw surface system.
class PetListPage extends StatelessWidget {
  const PetListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const PetNotLoggedInView();
        }

        final user = authState.user;
        final isVetOrStaff = user.isOwnerAdmin;

        if (isVetOrStaff) {
          // Vet/Staff/Admin see all pets
          return BlocProvider(
            create: (context) =>
                PetBloc(petRepository: context.read<PetRepository>())
                  ..add(const LoadAllPets()),
            child: const StaffPetListView(),
          );
        } else {
          // Pet owners see only their pets
          final ownerId = user.id!;
          return BlocProvider(
            create: (context) =>
                PetBloc(petRepository: context.read<PetRepository>())
                  ..add(LoadPets(ownerId: ownerId)),
            child: PetListView(ownerId: ownerId),
          );
        }
      },
    );
  }
}
