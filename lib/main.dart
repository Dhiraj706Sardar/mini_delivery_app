import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/navigation_service.dart';
import 'presentation/blocs/restaurant/restaurant_bloc.dart';
import 'presentation/blocs/menu/menu_bloc.dart';
import 'presentation/blocs/cart/cart_bloc.dart';
import 'presentation/blocs/order/order_bloc.dart';
import 'data/repositories/restaurant_repository_impl.dart';
import 'core/network/api_client.dart';
import 'data/datasources/cart_persistence_datasource.dart';
import 'data/datasources/menu_cache_datasource.dart';
import 'data/datasources/mock_cart_persistence_datasource.dart';
import 'data/datasources/mock_menu_cache_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FoodDeliveryApp());
}

class FoodDeliveryApp extends StatefulWidget {
  const FoodDeliveryApp({super.key});

  @override
  State<FoodDeliveryApp> createState() => _FoodDeliveryAppState();
}

class _FoodDeliveryAppState extends State<FoodDeliveryApp> {
  late final ApiClient apiClient;
  late final CartPersistenceDataSource cartPersistenceDataSource;
  late final MenuCacheDataSource menuCacheDataSource;
  late final RestaurantRepositoryImpl restaurantRepository;

  @override
  void initState() {
    super.initState();
    
    // Initialize dependencies
    apiClient = ApiClient();
    cartPersistenceDataSource = MockCartPersistenceDataSource();
    menuCacheDataSource = MockMenuCacheDataSource();
    restaurantRepository = RestaurantRepositoryImpl(
      apiClient: apiClient,
      menuCache: menuCacheDataSource,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RestaurantBloc>(
          create: (context) => RestaurantBloc(restaurantRepository: restaurantRepository),
        ),
        BlocProvider<MenuBloc>(
          create: (context) => MenuBloc(
            restaurantRepository: restaurantRepository,
          ),
        ),
        BlocProvider<CartBloc>(
          create: (context) => CartBloc(
            persistenceDataSource: cartPersistenceDataSource,
          ),
        ),
        BlocProvider<OrderBloc>(
          create: (context) => OrderBloc(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigationService.navigatorKey,
        initialRoute: AppRoutes.initial,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
