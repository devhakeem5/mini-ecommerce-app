import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_commerce_app/domain/entities/product.dart';
import 'package:mini_commerce_app/presentation/cart/cubit/cart_cubit.dart';
import 'package:mini_commerce_app/presentation/cart/cubit/cart_state.dart';
import 'package:mini_commerce_app/presentation/products/widgets/product_card.dart';
import 'package:mini_commerce_app/presentation/profile/cubit/locale_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockCartCubit extends MockCubit<CartState> implements CartCubit {
  MockCartCubit() {
    when(() => state).thenReturn(const CartInitial());
  }
}

class MockLocaleCubit extends MockCubit<LocaleState> implements LocaleCubit {
  MockLocaleCubit() {
    when(() => state).thenReturn(const LocaleState(languageCode: 'en'));
  }
}

class FakeImageProvider extends ImageProvider<FakeImageProvider> {
  @override
  Future<FakeImageProvider> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter loadImage(FakeImageProvider key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(_createImage());
  }

  Future<ImageInfo> _createImage() async {
    return ImageInfo(image: await _createTestImage());
  }

  Future<dynamic> _createTestImage() async {
    throw UnimplementedError();
  }
}

void main() {
  late MockCartCubit mockCartCubit;
  late MockLocaleCubit mockLocaleCubit;

  setUpAll(() {
    registerFallbackValue(const CartInitial());
    registerFallbackValue(const LocaleState(languageCode: 'en'));
    registerFallbackValue(
      const Product(
        id: 0,
        title: '',
        description: '',
        brand: '',
        category: '',
        price: 0,
        discountPercentage: 0,
        rating: 0,
        thumbnail: '',
        images: [],
        availabilityStatus: '',
      ),
    );
  });

  setUp(() {
    mockCartCubit = MockCartCubit();
    mockLocaleCubit = MockLocaleCubit();
  });

  const tProduct = Product(
    id: 1,
    title: 'Test Perfume',
    description: 'A nice perfume',
    brand: 'Brand',
    category: 'Fragrances',
    price: 100.0,
    discountPercentage: 0.0,
    rating: 4.5,
    thumbnail: 'http://example.com/image.jpg',
    images: [],
    availabilityStatus: 'In Stock',
  );

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CartCubit>.value(value: mockCartCubit),
        BlocProvider<LocaleCubit>.value(value: mockLocaleCubit),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ProductCard(product: tProduct)),
      ),
    );
  }

  testWidgets('ProductCard renders title and price', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Test Perfume'), findsOneWidget);
    expect(find.text('\$100.0'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('tapping Add to Cart triggers cubit', (tester) async {
    when(() => mockCartCubit.addToCart(any())).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.tap(find.byIcon(Icons.add));

    verify(() => mockCartCubit.addToCart(tProduct)).called(1);
  });
}
