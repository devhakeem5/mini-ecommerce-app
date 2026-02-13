# Architecture Document

## Mini Commerce App — v1.0.1

---

## 1. Architectural Style

**Clean Architecture + Feature-First Presentation Layer**

The application follows Robert C. Martin's Clean Architecture principles with three concentric layers, adapted for Flutter:

```
┌─────────────────────────────────────────┐
│             Presentation                │
│   (UI, Cubits, Widgets, Animations)     │
├─────────────────────────────────────────┤
│               Domain                    │
│   (Entities, Use Cases, Repo Interfaces)│
├─────────────────────────────────────────┤
│                Data                     │
│   (Repo Impls, Data Sources, Models)    │
├─────────────────────────────────────────┤
│                Core                     │
│   (DI, Theme, Localization, Network)    │
└─────────────────────────────────────────┘
```

**Feature-first** organization at the presentation layer: `products/`, `cart/`, `profile/`, `common/` — each containing their own `cubit/`, `pages/`, and `widgets/` directories.

---

## 2. Layer Breakdown

### 2.1 Domain Layer (`lib/domain/`)

**Zero framework dependencies**. Contains only pure Dart.

| Component | Count | Files |
|-----------|-------|-------|
| Entities | 7 | `Product`, `Cart`, `CartItem`, `Category`, `ProductsResult`, `Address`, `User` |
| Repository Interfaces | 7 | `ProductsRepository`, `CartRepository`, `CategoryRepository`, `SearchHistoryRepository`, `AddressRepository`, `LocaleRepository`, `UserRepository` |
| Use Cases | 20 | 5 products, 6 cart, 3 search, 4 address, 2 locale |

**Key Design Decisions**:
- `ProductsRepository` returns `Stream<Either<Failure, ProductsResult>>` — enabling the Stale-While-Revalidate pattern where cache and remote results are yielded sequentially.
- `CartRepository` returns `Future<Either<Failure, T>>` — cart is local-only, no streaming needed.
- `ProductsResult` wraps `List<Product>` with an `isOffline` flag, allowing the presentation layer to show offline indicators without coupling to network awareness.

### 2.2 Data Layer (`lib/data/`)

Implements domain interfaces. Depends on domain layer (downward only).

| Component | Details |
|-----------|---------|
| **Remote Data Sources** | `ProductsRemoteDataSourceImpl` — Dio HTTP client querying DummyJSON API |
| **Local Data Sources** | 5 implementations: Products (Hive), Cart (Hive), Search History (Hive), Address (Hive), Locale (Hive) |
| **Models** | `ProductModel`, `CartItemModel`, `AddressModel`, `UserModel`, `ProductOptionConfig` |
| **Repositories** | 7 implementations mapping to domain interfaces |

**Models vs Entities**: Models contain JSON serialization logic (`fromJson`, `toJson`). They convert to domain entities via `.toEntity()`. Entities are pure data holders with no serialization concern.

### 2.3 Presentation Layer (`lib/presentation/`)

Framework-dependent. Depends on domain layer for entities and use cases (injected via DI).

| Feature | Cubits | Pages | Widgets |
|---------|--------|-------|---------|
| Products | `ProductsCubit`, `ProductListCubit`, `SearchCubit`, `CategoriesCubit`, `PromotionsCubit` | `HomePage`, `AllProductsPage`, `ProductDetailsPage`, `SearchPage` | `ProductCard`, `CategoryList`, `PromotionsSlider`, `BrandsList`, `NewArrivalsSection`, `RecomendedSection`, etc. |
| Cart | `CartCubit`, `AddressCubit` | `CartPage`, `ShippingInfoPage`, `CheckoutPage`, `OrderConfirmationPage` | Cart item widgets |
| Profile | `ProfileCubit`, `LocaleCubit` | Profile/Settings page | — |
| Common | — | — | `FlyToCartOverlay`, `FlyToCartController`, `VisualCartOverlay`, `VisualCartController`, `OfflineIndicator`, `OfflineBanner`, `OfflineWidget`, `CustomToast`, `CustomErrorWidget`, `EmptyWidget`, `SkeletonLoaders`, `MainBottomNav`, `EntranceAnimation`, `SectionTitle`, `CustomCachedImage` |

### 2.4 Core Layer (`lib/core/`)

Shared infrastructure and cross-cutting concerns.

| Module | Files | Purpose |
|--------|-------|---------|
| `di/` | `service_locator.dart` | GetIt registrations for all dependencies |
| `error/` | `failures.dart`, `exceptions.dart` | Failure hierarchy (`ServerFailure`, `CacheFailure`, `NetworkFailure`), exception classes |
| `network/` | `connectivity_cubit.dart`, `connectivity_service.dart`, `connectivity_state.dart`, `offline_sync_service.dart` | Real-time connectivity monitoring, sync on reconnection |
| `storage/` | `hive_service.dart` | Hive initialization (box opening) |
| `theme/` | `app_theme.dart`, `app_colors.dart` | Light/Dark theme definitions, color palette |
| `localization/` | `app_localizations.dart` | 230+ AR/EN translation strings, `context.tr()` extension |
| `util/` | `responsive.dart` | Responsive breakpoint widget (mobile/tablet/desktop) |

---

## 3. Dependency Rule

Dependencies point **inward only**:

```
Presentation → Domain ← Data
                ↑
               Core (infrastructure, injected)
```

- **Domain** has zero imports from `data/`, `presentation/`, or `core/`.
- **Data** imports from `domain/` (repository interfaces, entities) and `core/` (failures).
- **Presentation** imports from `domain/` (entities, use cases) — never directly from `data/`.
- **Core** is utility infrastructure; it may be imported by any layer but imports none of them (with the exception of `service_locator.dart` which wires everything together).

**Verification**: Domain entity files (`Product`, `Cart`, `CartItem`, etc.) contain only `package:equatable/equatable.dart` imports. No Flutter, no Hive, no Dio.

---

## 4. Repository Pattern

Each feature domain exposes an abstract repository interface:

```dart
// domain/repositories/products_repository.dart
abstract class ProductsRepository {
  Stream<Either<Failure, ProductsResult>> getProducts({...});
  Stream<Either<Failure, ProductsResult>> searchProducts({...});
  Future<Either<Failure, ProductsResult>> searchProductsLocally({...});
}
```

Implementations in `data/repositories/` coordinate between local and remote data sources:

```dart
// data/repositories/products_repository_impl.dart
class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsRemoteDataSource remote;
  final ProductsLocalDataSource local;
  // ...
}
```

**Why Stream return type for ProductsRepository**: The Stale-While-Revalidate pattern requires yielding multiple values — first from cache, then from network. Dart `async*` generators with `yield` make this natural:

```
yield Right(cachedResult)  →  yield Right(remoteResult)
```

**Why Future return type for CartRepository**: Cart is local-only. Each operation produces a single result. No streaming needed.

---

## 5. State Management Strategy

### Cubit (Bloc Pattern)

All state management uses `Cubit` from `flutter_bloc`.

**Why Cubit over full Bloc**: The app's state transitions are triggered by method calls, not events. Cubit provides a simpler API (`emit(state)` vs event-to-state mapping) with equivalent power for this use case. There are no complex event transformations (e.g., `debounce`, `switchMap`) that would benefit from Bloc's event stream.

**State Classes**: All states extend `Equatable` for value-based equality, preventing redundant widget rebuilds when the same state is emitted.

**Cubit Inventory**:

| Cubit | Scope | Registration |
|-------|-------|-------------|
| `ProductsCubit` | Global (MultiBlocProvider in `main.dart`) | `registerFactory` |
| `CategoriesCubit` | Global | `registerFactory` |
| `CartCubit` | Global | `registerFactory` |
| `SearchCubit` | Scoped (created per SearchPage) | `registerFactory` |
| `ProductListCubit` | Scoped (created per AllProductsPage) | `registerFactory` |
| `PromotionsCubit` | Scoped | `registerFactory` |
| `ProfileCubit` | Global | `registerFactory` |
| `LocaleCubit` | Global | `registerLazySingleton` |
| `ConnectivityCubit` | Global | `registerFactory` |
| `AddressCubit` | Global | `registerFactory` |

**Notable**: `LocaleCubit` is a `LazySingleton` because the locale state must be shared across the entire app and persist across widget rebuilds.

---

## 6. Error Handling Strategy

### Either<Failure, T> (Functional Error Handling)

Using `dartz` package. **All repository methods return `Either<Failure, T>`**. No exceptions escape the data layer.

```
Repository → Either<Failure, T>
UseCase    → passes through Either
Cubit      → fold(onFailure, onSuccess)
UI         → renders error/loaded state
```

**Why Either instead of throwing exceptions**:
1. **Compile-time safety**: Return types force callers to handle both success and failure paths.
2. **Composability**: `Either` chains naturally with `map`, `flatMap`, `fold`.
3. **No hidden control flow**: Exceptions create invisible fallthrough paths. `Either` makes error handling explicit and visible in the type signature.
4. **Testability**: Tests verify return values, not `expect(() => ..., throwsA(...))` patterns.

**Failure Hierarchy**:
```dart
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure { ... }
class CacheFailure extends Failure { ... }
class NetworkFailure extends Failure { ... }
```

---

## 7. Concurrency Strategy

### Sequential Queue in CartRepositoryImpl

```dart
Future<void> _processingQueue = Future.value();

Future<T> _enqueue<T>(Future<T> Function() task) {
  final completer = Completer<T>();
  _processingQueue = _processingQueue
      .then((_) => task()
          .then(completer.complete)
          .catchError(completer.completeError))
      .catchError((_) {});
  return completer.future;
}
```

**How it works**: `_processingQueue` is a `Future` chain. Each new task is appended via `.then()`, ensuring sequential execution. A `Completer` bridges the result back to the caller.

**Why Sequential Queue over DB Transaction**: Hive does not support transactions. The queue provides application-level serialization:
- **Reads are always fresh**: Each enqueued task re-reads the current state from Hive before mutating.
- **Writes are ordered**: No two writes can interleave.
- **Error isolation**: `catchError` on the queue chain prevents one failed task from blocking subsequent tasks.

**Trade-off**: If Hive crashes between a read and write within a single enqueued task, data could be inconsistent. For a local shopping cart, this risk is acceptable and far simpler than implementing a WAL or transaction log.

---

## 8. Offline Strategy

### Stale-While-Revalidate (Cache-First + Silent Refresh)

Implemented in `ProductsRepositoryImpl._fetchProductsStream()`:

```
1. Read from local cache (Hive) by composite cache key.
   → If cache hit: yield Right(ProductsResult(isOffline: true))

2. Fetch from remote API.
   → On success: update cache, yield Right(ProductsResult(isOffline: false))
   → On failure: if cache was already yielded, silently absorb the error.
                  if no cache exists, yield Left(NetworkFailure())

3. Special case for search: on remote failure, fallback to
   local.searchLocalProducts() across all cached data.
```

**Cache Key Strategy**: Composite keys encode pagination position and filters:
- Browse: `products_skip_{skip}_limit_{limit}_sort_{sortBy}_order_{order}`
- Category: `category_{slug}_skip_{skip}_limit_{limit}`
- Search: `search_{query}_skip_{skip}_limit_{limit}`

This ensures each unique page/filter combination has its own cache entry.

**Verified**: The cache read is always attempted first, and the remote fetch runs afterward. The UI receives two sequential emissions — first cached (fast), then fresh (delayed). This is the Stale-While-Revalidate pattern.

---

### Offline Write Synchronization (Design-Ready Layer)

The project includes a structured `OfflineSyncService` to demonstrate how deferred write operations would be reconciled with a backend in a production system.

Since the DummyJSON API is read-only, full write synchronization is intentionally not implemented. The service currently acts as a strategy placeholder to illustrate extensibility without introducing unnecessary complexity.

---

## 9. Pagination Merge Strategy

### Deduplication Approach

Both `ProductsCubit._dedup()` and `SearchCubit._dedup()` use ID-keyed map:

```dart
List<Product> _dedup(List<Product> products) {
  final map = <int, Product>{};
  for (final p in products) {
    map[p.id] = p;
  }
  return map.values.toList();
}
```

**Behavior**: Later entries overwrite earlier ones. When merging `currentProducts + newProducts`, if the API returns a product that was already in the current list (e.g., due to data shifting between pages), the latest version is kept.

**End-of-list detection**: `hasReachedMax = newProducts.length < _pageSize`. Once set, `loadMoreProducts()` / `loadMoreResults()` returns immediately without API call.

**Guard against concurrent fetches**: `_isFetching` boolean flag prevents duplicate pagination requests from scroll events.

---

## 10. Price Synchronization Strategy

### Where syncPrices is Triggered

`main.dart` — `BlocListener<ProductsCubit, ProductsState>`:

```dart
BlocListener<ProductsCubit, ProductsState>(
  listener: (context, state) {
    if (state is ProductsLoaded) {
      context.read<CartCubit>().syncPrices(state.products);
    }
  },
),
```

**Flow**: When the products list loads (from cache or remote), the latest product data is passed to `CartCubit.syncPrices()`, which calls `UpdateCartPricesUseCase` → `CartRepositoryImpl.updateProductPrices()`.

**Why orchestration at the app root**: This coupling is intentional — the cart needs to react to product data changes regardless of which screen the user is on. Placing the listener at the `MaterialApp` level ensures it always runs.

**What syncPrices does**: Compares `freshProduct.price != item.product.price` for each cart item against the latest product list. Only updates Hive and re-emits state if at least one price changed (`hasChanges` flag).

---

## 11. Folder Structure Rationale

```
lib/
├── core/                    # Cross-cutting concerns
│   ├── di/                  # Single service_locator.dart
│   ├── error/               # Failure/Exception hierarchy
│   ├── localization/        # Translation strings (AR/EN)
│   ├── network/             # Connectivity monitoring
│   ├── storage/             # Hive initialization
│   ├── theme/               # Design system (colors, themes)
│   └── util/                # Responsive helpers
│
├── domain/                  # Business rules (zero deps)
│   ├── entities/            # 7 domain entities
│   ├── repositories/        # 7 abstract interfaces
│   └── usecases/            # 20 single-responsibility use cases
│       ├── products/        # Get, Search, Category, New, Recommended
│       ├── cart/             # Add, Remove, Load, Update, Clear, Prices
│       ├── search/          # History CRUD
│       ├── address/         # CRUD + Seed
│       └── locale/          # Get, Set
│
├── data/                    # Implementation
│   ├── datasources/
│   │   ├── local/           # Hive data sources (5 interfaces + impls)
│   │   └── remote/          # Dio data source (1 interface + impl)
│   ├── models/              # JSON-serializable models
│   └── repositories/        # 7 repository implementations
│
└── presentation/            # Feature-first UI
    ├── products/            # Home, All Products, Details, Search
    │   ├── cubit/           # ProductsCubit, SearchCubit, etc.
    │   ├── pages/           # 4 pages
    │   └── widgets/         # Feature-specific widgets
    ├── cart/                # Cart, Shipping, Checkout, Confirmation
    │   ├── cubit/           # CartCubit, AddressCubit
    │   ├── pages/           # 4 pages
    │   └── widgets/         # Cart-specific widgets
    ├── profile/             # Settings
    │   └── cubit/           # ProfileCubit, LocaleCubit
    └── common/              # Shared presentation
        ├── fly_to_cart/     # Animation controller + overlay
        ├── visual_cart/     # Visual cart controller + overlay
        └── widgets/         # 11 reusable widgets
```

**Why feature-first in presentation**: Each feature directory (`products/`, `cart/`, `profile/`) is self-contained with its own cubits, pages, and widgets. This makes it possible to understand a feature by looking at a single directory, and reduces the cognitive overhead of navigating a flat cubit or page directory.

**Why not feature-first across all layers**: Domain and data layers are organized by type (entities, repositories, use cases) rather than by feature. This is because domain entities are shared across features (e.g., `Product` is used by products, cart, and search), and feature-first organization at the domain level would create duplication or cross-feature imports.

---

## 12. Decision Justifications

### Why Cubit over Full Bloc

Cubit was chosen because:
1. No complex event transformations are needed (no debounce/switchMap on events).
2. Search debounce is implemented manually with a `Timer` in the Cubit, which is simpler than Bloc's event transformer API.
3. All state transitions are triggered by explicit method calls, making Cubit's simpler API sufficient.
4. Cubit produces less boilerplate (no event classes, no `mapEventToState`).

### Why Either<Failure, T> Instead of Throwing Exceptions

Exceptions in Dart are unchecked. A repository method that throws has no compile-time indication of failure — callers may forget to catch. `Either` forces the caller to explicitly handle both paths via `fold()`. This aligns with the functional error-handling philosophy: make failures visible in the type system.

### Why Sequential Queue Over DB Transaction

Hive does not support ACID transactions. The sequential queue (`_processingQueue`) provides ordered execution without requiring a database engine. Each operation reads current state, mutates, and writes back — all within a single `_enqueue()` block. This is simpler and more debuggable than a transaction-based approach, with acceptable risk for local cart data.

### Why syncPrices is Orchestrated at the App Root

`syncPrices` must run whenever product data changes, regardless of which screen is active. A `BlocListener` at the `MaterialApp` level guarantees this. Placing it deeper in the widget tree would risk missing updates when the user navigates away from the products screen.

### Slivers Usage

The home page uses `SingleChildScrollView` with a `Column` of sections rather than `CustomScrollView` with `Slivers`. This was verified — each section (`PromotionsSlider`, `CategoryList`, `NewArrivalsSection`, etc.) is a self-contained widget with its own internal scrolling (horizontal lists use `ListView.builder` with `scrollDirection: Axis.horizontal`).

**Trade-off**: Slivers would provide more efficient lazy rendering for the overall vertical scroll. However, the current approach is simpler to compose — each section widget is independent and doesn't need to conform to a Sliver protocol. For the current number of sections, the performance impact is negligible.

---

## 13. Explicit Trade-offs

| Decision | Benefit | Cost |
|----------|---------|------|
| Hive over SQLite/Drift | Simple setup, no schema migration, fast read/write | No query language, no relational joins, no transactions |
| Sequential queue over DB transaction | Simpler implementation, no transaction framework needed | Not atomic at storage level; crash between read and write is unhandled |
| `Stream<Either>` for products | Natural Stale-While-Revalidate pattern | Subscribers must handle multiple emissions per request |
| Feature-first presentation, type-first domain | Features are self-contained; domain entities are shared cleanly | Mixed organizational style may be unfamiliar |
| Manual debounce Timer in Cubit | Full control over debounce behavior, simple implementation | Must manually manage Timer lifecycle (`cancel()` in `close()`) |
| `InheritedWidget` for FlyToCartController | No additional dependency, lightweight | Requires widget tree proximity; `maybeOf()` pattern needed for optional access |
| DummyJSON API | Real paginated API for realistic testing | No auth, no mutations, data is static |

---

## 14. Scalability Considerations

| Area | Current State | Scaling Path |
|------|--------------|-------------|
| **Local Storage** | Hive boxes with raw Maps | Migrate to Drift/SQLite for queryable, relational storage with migrations |
| **Cart Concurrency** | In-memory sequential queue | If multi-device sync is needed, move to server-side cart with optimistic concurrency control |
| **API Client** | Single Dio instance | Add interceptors for auth, retry, logging. Consider API versioning |
| **State Management** | Cubit per feature | If event-driven complexity grows, migrate individual Cubits to full Bloc |
| **Localization** | Hardcoded map in `app_localizations.dart` | Migrate to `.arb` files with `intl` package for standard Flutter localization |
| **Testing** | 18 tests covering critical paths | Expand with integration tests, golden tests, and widget tests per screen |

---

## 15. Maintainability Considerations

- **Single Responsibility Use Cases**: Each use case class has a single `call()` method. Adding new business rules means adding new use cases, not modifying existing ones.
- **DI Container**: All dependencies registered in `service_locator.dart`. Swapping implementations (e.g., SQLite for Hive) requires changing only the registration.
- **Equatable States**: Prevents subtle bugs from reference equality. Adding a new field to a state class requires updating `props` — the compiler doesn't enforce this, but `Equatable` makes it a conscious step.
- **No business logic in UI**: Pages and widgets delegate all logic to Cubits. No `await` calls or data transformations in `build()` methods.

---

## 16. Risks & Future Improvements

### Risks

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Hive data corruption on app crash during write | Low | Sequential queue reduces window; cart data is recoverable from API |
| DummyJSON API downtime | Medium | Cache-first strategy means existing users are unaffected; new installs would see empty state |
| Localization strings hardcoded | Low | Functional but blocks standard Flutter localization tooling |
| `ProductsResult` not `Equatable` | Low | Could cause unnecessary rebuilds in edge cases where the same data is re-emitted |

### Future Improvements

1. **Migration to `.arb`-based localization** for standard Flutter `intl` workflow.
2. **Integration tests** covering full user flows (browse → details → add to cart → checkout).
3. **Golden tests** for visual regression on key screens.
4. **Drift migration** for queryable local storage with proper schema versioning.
5. **Analytics layer** to track key user interactions (add-to-cart rate, search-to-browse ratio).
6. **Accessibility audit** — semantic labels, contrast ratios, screen reader support.
