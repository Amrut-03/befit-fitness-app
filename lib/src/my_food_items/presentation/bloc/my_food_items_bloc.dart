import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:befit_fitness_app/core/utils/logger.dart';
import 'package:befit_fitness_app/src/my_food_items/domain/usecases/get_food_items_usecase.dart';
import 'package:befit_fitness_app/src/my_food_items/domain/usecases/delete_food_item_usecase.dart';
import 'package:befit_fitness_app/src/my_food_items/presentation/bloc/my_food_items_event.dart';
import 'package:befit_fitness_app/src/my_food_items/presentation/bloc/my_food_items_state.dart';

/// BLoC for managing my food items state and operations
class MyFoodItemsBloc extends Bloc<MyFoodItemsEvent, MyFoodItemsState> {
  final GetFoodItemsUseCase getFoodItemsUseCase;
  final DeleteFoodItemUseCase deleteFoodItemUseCase;

  MyFoodItemsBloc({
    required this.getFoodItemsUseCase,
    required this.deleteFoodItemUseCase,
  }) : super(const MyFoodItemsInitial()) {
    on<LoadFoodItemsEvent>(_onLoadFoodItems);
    on<DeleteFoodItemEvent>(_onDeleteFoodItem);
    on<RefreshFoodItemsEvent>(_onRefreshFoodItems);
  }

  Future<void> _onLoadFoodItems(
    LoadFoodItemsEvent event,
    Emitter<MyFoodItemsState> emit,
  ) async {
    emit(const MyFoodItemsLoading());
    
    final result = await getFoodItemsUseCase();
    
    result.fold(
      (failure) {
        // Log error for monitoring
        AppLogger.e(
          'MyFoodItemsBloc: Failed to load food items',
          failure,
          StackTrace.current,
        );
        
        // Preserve previous state if available
        if (state is MyFoodItemsLoaded) {
          // Keep the previous data, just show error
          final previousState = state as MyFoodItemsLoaded;
          emit(MyFoodItemsError(failure.message));
          // Restore previous state after error
          emit(previousState);
        } else {
          emit(MyFoodItemsError(failure.message));
        }
      },
      (foodItems) {
        emit(MyFoodItemsLoaded(foodItems));
      },
    );
  }

  Future<void> _onDeleteFoodItem(
    DeleteFoodItemEvent event,
    Emitter<MyFoodItemsState> emit,
  ) async {
    // Input validation
    if (event.docId.isEmpty || event.type.isEmpty) {
      emit(const MyFoodItemsError('Document ID and type cannot be empty'));
      return;
    }

    // Preserve current state during deletion
    final currentState = state;
    if (currentState is MyFoodItemsLoaded) {
      emit(currentState); // Keep showing current items
    }

    final result = await deleteFoodItemUseCase(
      DeleteFoodItemParams(docId: event.docId, type: event.type),
    );

    result.fold(
      (failure) {
        // Log error for monitoring
        AppLogger.e(
          'MyFoodItemsBloc: Failed to delete food item',
          failure,
          StackTrace.current,
        );
        
        // Preserve previous state if available
        if (currentState is MyFoodItemsLoaded) {
          emit(MyFoodItemsError(failure.message));
          // Restore previous state after error
          emit(currentState);
        } else {
          emit(MyFoodItemsError(failure.message));
        }
      },
      (_) {
        // Reload food items after successful deletion
        add(const LoadFoodItemsEvent());
      },
    );
  }

  Future<void> _onRefreshFoodItems(
    RefreshFoodItemsEvent event,
    Emitter<MyFoodItemsState> emit,
  ) async {
    add(const LoadFoodItemsEvent());
  }

  @override
  Future<void> close() {
    AppLogger.d('MyFoodItemsBloc: Closing');
    return super.close();
  }
}
