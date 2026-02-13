# Software Requirements Specification (SRS)

## Mini Commerce App — v1.0.1

---

## 1. Functional Requirements

### Product Browsing

| ID | Requirement | Verified Implementation |
|----|-------------|------------------------|
| FR-1 | The system shall display a paginated product list with infinite scroll. | `ProductsCubit._fetchProducts()` — 20-item pages, `loadMoreProducts()` triggered by scroll position. |
| FR-2 | Each page fetch shall deduplicate products by ID before appending. | `ProductsCubit._dedup()` — `Map<int, Product>` keyed by `product.id`. |
| FR-3 | Pagination shall stop when the API returns fewer items than the page size. | `hasReachedMax = newProducts.length < _pageSize` in `ProductsCubit`. |
| FR-4 | The system shall display product image, name, price, and discount percentage. | `Product` entity fields: `title`, `price`, `discountPercentage`, `thumbnail`. `discountedPrice` computed getter. |
| FR-5 | The system shall display skeleton shimmer loaders during initial product loading. | `skeleton_loaders.dart` — Shimmer widgets used in product grids and horizontal lists. |
| FR-6 | The system shall support category-based product filtering. | `GetProductsByCategoryUseCase` → `ProductsRepository.getProductsByCategory()` → API `/products/category/{slug}`. |
| FR-7 | The system shall display a promotions slider, categories, brands, new arrivals, and recommended sections on the home screen. | `HomePage._HomeContent` — `PromotionsSlider`, `CategoryList`, `NewArrivalsSection`, `BrandsList`, `RecomendedSection`, `BlogsList`. |

### Product Details

| ID | Requirement | Verified Implementation |
|----|-------------|------------------------|
| FR-8 | The system shall display a large product image with Hero transition animation. | `ProductDetailsPage` — Hero widget wrapping product thumbnail with `tag: 'product_${product.id}'`. |
| FR-9 | The system shall display product name, price, star rating, and discount information. | `ProductDetailsPage._buildPriceRow()` and `ProductInfoRow` widget. |
| FR-10 | The system shall provide category-aware variant selectors. | `_getProductOptions(category)` — `ProductOptionConfig` maps categories to size/RAM/storage options. |
| FR-11 | The system shall display product description via bottom sheet. | `_showDescriptionSheet()` — `showModalBottomSheet` with full description text. |
| FR-12 | The system shall display related products. | `RelatedProductsSection` widget in product details page. |
| FR-13 | The system shall disable "Add to Cart" for out-of-stock products and show an Arabic toast message. | Case-insensitive `availabilityStatus` check; disabled button; Arabic toast via `CustomToast`. |

### Cart

| ID | Requirement | Verified Implementation |
|----|-------------|------------------------|
| FR-14 | The system shall persist cart items locally using Hive. | `CartLocalDataSource.saveCart()` → Hive box. `CartRepositoryImpl._saveModels()` serializes `CartItemModel` to Map. |
| FR-15 | The system shall survive app restarts with cart data intact. | `CartCubit.loadCart()` called on app init in `main.dart` via `BlocProvider`. |
| FR-16 | The system shall increment quantity when adding a duplicate product. | `CartRepositoryImpl.addToCart()` — `indexWhere` checks existing; increments `quantity + 1` if found. |
| FR-17 | The system shall enforce a minimum quantity of 1. | `CartRepositoryImpl.updateQuantity()` — `if (quantity < 1) return`. `CartCubit.decrement()` — calls `removeFromCartUseCase` at quantity ≤ 1. |
| FR-18 | The system shall support swipe-to-delete with 5-second undo. | `CartPage` — Dismissible widget with SnackBar undo action. `undoRemoveItem()` restores item and original quantity. |
| FR-19 | The system shall calculate subtotal, discount total, and savings. | `Cart` entity: `totalPrice` (sum of `item.product.price * quantity`), `totalDiscountedPrice` (sum of `item.product.discountedPrice * quantity`), `totalSavings` (difference). |
| FR-20 | The system shall synchronize cart prices with the latest server data. | `CartCubit.syncPrices()` → `UpdateCartPricesUseCase` → `CartRepositoryImpl.updateProductPrices()`. Triggered by `BlocListener<ProductsCubit, ProductsState>` in `main.dart`. |
| FR-21 | The system shall support clearing all cart items with a confirmation dialog. | `CartPage._showClearDialog()` → `CartCubit.clearCart()` → `ClearCartUseCase`. |

### Search

| ID | Requirement | Verified Implementation |
|----|-------------|------------------------|
| FR-22 | The system shall debounce search input by 500 milliseconds. | `SearchCubit.onSearchChanged()` — `Timer(const Duration(milliseconds: 500), ...)`. |
| FR-23 | The system shall show search auto-suggestions from persisted history. | `_fullHistory.where((e) => e.toLowerCase().contains(query.toLowerCase()))` emitted as `SearchHistoryLoaded.suggestions`. |
| FR-24 | The system shall execute local search first, then remote search. | `SearchCubit.search()` — calls `searchProductsLocallyUseCase` first, emits local results; then calls `searchProductsUseCase` stream. |
| FR-25 | The system shall protect against stale search responses using ID versioning. | `_searchId` integer incremented on each `search()` call. All async results check `currentSearchId == _searchId` before emitting. |
| FR-26 | The system shall persist search history and support deletion of individual entries. | `AddToSearchHistoryUseCase`, `GetSearchHistoryUseCase`, `DeleteSearchHistoryUseCase` backed by `SearchHistoryLocalDataSource` (Hive). |
| FR-27 | The system shall fallback to searching all cached products when offline. | `ProductsRepositoryImpl._fetchProductsStream()` — on remote failure with `query != null`, calls `local.searchLocalProducts(query)`. |
| FR-28 | The system shall support paginated search results with deduplication. | `SearchCubit.loadMoreResults()` with `_dedup()` and `hasReachedMax` detection. |

### Checkout Flow

| ID | Requirement | Verified Implementation |
|----|-------------|------------------------|
| FR-29 | The system shall provide a shipping information page with address selection. | `ShippingInfoPage` — address management via `AddressCubit`. |
| FR-30 | The system shall provide a checkout page with payment method selection and order summary. | `CheckoutPage` — payment selection with discount/total breakdown. |
| FR-31 | The system shall display an animated order confirmation page. | `OrderConfirmationPage` — animated confirmation with order details. |

### Profile / Settings

| ID | Requirement | Verified Implementation |
|----|-------------|------------------------|
| FR-32 | The system shall support toggling between Light and Dark themes. | `ProfileCubit` — theme toggle. `AppTheme.lightTheme` and `AppTheme.darkTheme`. `ThemeMode.system` default. |
| FR-33 | The system shall support toggling between Arabic and English. | `LocaleCubit` with persisted locale preference via `LocaleRepository`. |

---

## 2. Non-Functional Requirements

| ID | Requirement | Implementation |
|----|-------------|---------------|
| NFR-1 | **Performance**: Cached data shall render within 500ms of app launch. | Repository reads Hive cache synchronously in `_fetchProductsStream()` before any network call. |
| NFR-2 | **Performance**: Image loading shall use HTTP caching to avoid redundant downloads. | `cached_network_image` package handles disk/memory caching automatically. |
| NFR-3 | **Performance**: Widget rebuilds shall be minimized through targeted state subscriptions. | `BlocBuilder` / `BlocListener` scoped to specific Cubits. `Equatable` states prevent unnecessary emissions. |
| NFR-4 | **Responsiveness**: UI shall adapt to mobile, tablet, and desktop screen sizes. | `Responsive` utility widget in `core/util/responsive.dart` applies layout variants by breakpoint. |
| NFR-5 | **Reliability**: All cart operations shall be sequentially ordered to prevent race conditions. | `CartRepositoryImpl._processingQueue` — `Future`-chained sequential queue via `_enqueue()`. |
| NFR-6 | **Reliability**: All repository operations shall return `Either<Failure, T>` instead of throwing exceptions. | `dartz` package. `ServerFailure`, `CacheFailure`, `NetworkFailure` subtypes. |
| NFR-7 | **Maintainability**: Code shall follow Clean Architecture with strict layer separation. | `domain/` contains entities, repository interfaces, and use cases with zero framework imports. `data/` implements repositories. `presentation/` contains UI. |
| NFR-8 | **Testability**: Business logic shall be independently testable via mock injection. | 18 test files across core, data, domain, and presentation layers using `mocktail` and `bloc_test`. |
| NFR-9 | **Accessibility**: UI shall support RTL layout for Arabic locale. | `flutter_localizations` delegates handle RTL/LTR based on `Locale`. |

---

## 3. Constraints

| Constraint | Details |
|-----------|---------|
| **API Dependency** | Application depends on `https://dummyjson.com/products`. No authentication required. API may rate-limit or become unavailable. |
| **Local Storage Engine** | Hive is used for all local persistence. No migration framework — data stored as raw `Map<String, dynamic>`. |
| **No Backend** | No server-side logic. Cart, addresses, search history, and locale preferences are local-only. |
| **Checkout is UI-only** | The checkout flow does not submit orders to any backend. It is a UI demonstration. |
| **Flutter SDK** | Requires SDK `^3.10.0` as specified in `pubspec.yaml`. |

---

## 4. External Interfaces

### 4.1 API Integration

| Interface | Endpoint | Method | Parameters |
|-----------|----------|--------|-----------|
| Get Products | `GET /products` | HTTP GET | `limit`, `skip`, `sortBy`, `order` |
| Search Products | `GET /products/search` | HTTP GET | `q`, `limit`, `skip` |
| Get by Category | `GET /products/category/{slug}` | HTTP GET | `limit`, `skip` |
| Get Categories | `GET /products/categories` | HTTP GET | — |

**Client**: Dio HTTP client (`dio: ^5.9.1`), configured as lazy singleton via GetIt.

**Data Source Abstraction**:
- `ProductsRemoteDataSource` (abstract) → `ProductsRemoteDataSourceImpl` (Dio implementation)
- All remote calls return `List<ProductModel>` which are converted to domain entities via `.toEntity()`.

### 4.2 Local Storage

| Store | Hive Box | Data |
|-------|----------|------|
| Products Cache | Products box | `Map<String, dynamic>` per product, keyed by cache key |
| Cart | Cart box | `List<Map>` where each map contains `product` (Map) and `quantity` (int) |
| Search History | Search History box | `List<String>` of recent queries |
| Addresses | Addresses box | `List<Map>` of address data |
| Locale | Locale box | `String` language code |

---

## 5. Offline Behavior Specification

### 5.1 Product Browsing (Offline)

1. `ProductsRepositoryImpl._fetchProductsStream()` reads cache by composite key (e.g., `products_skip_0_limit_20_sort_none_order_none`).
2. If cache exists → yield `ProductsResult(products: cached, isOffline: true)`.
3. Remote fetch attempted → fails silently if no connectivity.
4. If no cache existed and remote fails → yield `Left(NetworkFailure())`.

### 5.2 Search (Offline)

1. `SearchCubit.search()` calls `searchProductsLocallyUseCase` first — always available.
2. Remote search stream attempted → on failure, `ProductsRepositoryImpl` falls back to `local.searchLocalProducts(query)` which searches across **all** cached products (all cache keys).
3. If local fallback finds results → yield with `isOffline: true`. Otherwise → yield `NetworkFailure`.

### 5.3 Cart (Offline)

- Cart is fully local. All operations (`add`, `remove`, `update`, `clear`, `load`) use Hive directly. No network dependency.
- `syncPrices` only runs when `ProductsLoaded` state emits (i.e., when remote data arrives). Offline → no sync triggered, which is expected and safe.

### 5.4 Connectivity Monitoring

- `ConnectivityService` wraps `connectivity_plus` package.
- `ConnectivityCubit` emits `ConnectivityOnline(wasOffline: bool)` or `ConnectivityOffline`.
- On reconnection: `OfflineSyncService.syncPendingActions()` triggered.
- UI: `OfflineIndicator` banner, `CustomToast` for connectivity change notifications.

---

## 6. Concurrency Guarantees

### Cart Sequential Queue

`CartRepositoryImpl` implements a `_processingQueue` pattern:

```dart
Future<void> _processingQueue = Future.value();

Future<T> _enqueue<T>(Future<T> Function() task) {
  final completer = Completer<T>();
  _processingQueue = _processingQueue
      .then((_) => task().then(completer.complete).catchError(completer.completeError))
      .catchError((_) {});
  return completer.future;
}
```

**Guarantee**: All cart mutations (`addToCart`, `updateQuantity`, `removeFromCart`, `clearCart`, `updateProductPrices`) are serialized through `_enqueue()`. Even if `addToCart` is called rapidly multiple times, each operation waits for the previous one to complete before reading the current state and writing the result.

**Trade-off**: This is a sequential queue, not a database transaction. It prevents race conditions at the application layer but does not provide atomicity guarantees at the storage layer. For a local Hive store, this is sufficient.

### Search Race Condition Prevention

`SearchCubit._searchId` acts as a monotonically increasing version counter:

```dart
final int currentSearchId = ++_searchId;
// ... async work ...
if (currentSearchId != _searchId) return; // discard stale result
```

This prevents a slow API response from Search A overwriting results from the newer Search B.

---

## 7. Error Handling Rules

| Layer | Error Handling Strategy |
|-------|----------------------|
| **Data / Repository** | Catch exceptions → return `Left(Failure)`. Never throw to callers. |
| **Domain / UseCase** | Pass-through `Either<Failure, T>` from repository. No exception handling. |
| **Presentation / Cubit** | `result.fold((failure) => emit(ErrorState), (data) => emit(LoadedState))`. |
| **UI** | Error states rendered via `CustomErrorWidget` with retry callback. Errors displayed via `CustomToast` or `SnackBar`. |

**Failure Types**:
- `ServerFailure` — API returned an error or unexpected response.
- `CacheFailure` — Hive read/write operation failed.
- `NetworkFailure` — No internet connectivity (default: "No Internet Connection").

All failures extend `Failure` (abstract, `Equatable`) with a `message` field.
