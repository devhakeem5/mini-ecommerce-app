# Mini Commerce App

A Flutter e-commerce application built with **Clean Architecture**, **Cubit state management**, and an **offline-first** data strategy. Designed to demonstrate architectural maturity, data consistency under concurrency, and polished UX in a constrained scope.

**API**: [DummyJSON Products](https://dummyjson.com/products) — pagination, search, and category endpoints.

---

## Engineering Highlights

| Area | Implementation |
|------|---------------|
| **Clean Architecture** | Strict 3-layer separation: `domain/` (entities, use cases, repo interfaces) → `data/` (repo implementations, data sources, models) → `presentation/` (cubits, pages, widgets). Domain has zero framework dependencies. |
| **Offline-First** | Stale-While-Revalidate pattern in `ProductsRepositoryImpl`: cache is read first and yielded immediately, remote fetch runs in background, UI updates transparently. User never blocks on network. |
| **Concurrency-Safe Cart** | Sequential queue (`_processingQueue`) in `CartRepositoryImpl` serializes all cart mutations. Prevents race conditions from rapid add/remove operations without requiring database transactions. |
| **Debounced Search** | 500ms debounce with local-first strategy (local DB searched immediately, remote results sync in background). Search ID versioning (`_searchId`) prevents stale API responses from overwriting newer results. |
| **Fly-to-Cart Animation** | Quadratic Bézier curve overlay animation (600ms, `easeInOutCubic`) — product thumbnail flies from card to basket icon. Non-blocking: user continues browsing during animation. |
| **Functional Error Model** | `dartz` `Either<Failure, T>` across all repository boundaries. Three failure types: `ServerFailure`, `CacheFailure`, `NetworkFailure`. No unchecked exceptions cross layer boundaries. |
| **Pagination with Deduplication** | ID-keyed `Map` dedup in `ProductsCubit` and `SearchCubit` prevents duplicate entries when API data shifts between pages. `hasReachedMax` stops requests when page size is not filled. |
| **Price Synchronization** | `CartCubit.syncPrices()` triggered by `BlocListener` in `main.dart` on every `ProductsLoaded` emission. Compares and persists only changed prices to Hive. |

---

## Architecture

```
lib/
├── core/           → DI (GetIt), Error types, Localization (AR/EN), Connectivity, Theme, Hive init
├── domain/         → 7 Entities, 7 Repository interfaces, 20 Use Cases (zero framework deps)
├── data/           → 7 Repository implementations, 6 Data Sources (5 local Hive + 1 remote Dio), 5 Models
└── presentation/   → Feature-first: products/ cart/ profile/ common/ (cubits, pages, widgets)
```

**Data Flow**: `UI → Cubit → UseCase → Repository Interface (Domain) → Repository Impl (Data) → Local/Remote DataSource`

**Offline Strategy**: Repository reads cache → yields cached result → fetches remote → updates cache → yields fresh result. If remote fails silently when cache exists.

---

## Screens

### Mandatory

| Screen | Key Features |
|--------|-------------|
| **Home / Browse** | Promotions slider, categories, brands, new arrivals, recommended. Infinite scroll (20/page). Skeleton loaders. Cached data instant on launch. Auto-retry pagination on reconnect. |
| **Product Details** | Hero transition, image gallery, star rating, category-aware variant selectors, description bottom sheet, related products, fly-to-cart animation. Out-of-stock gating. |
| **Cart** | Hive-persisted. Quantity controls (min 1). Swipe-to-delete with 5s undo. Subtotal/discount/total in domain entity. Price sync on product load. Clear with confirmation. |

### Optional

| Screen | Description |
|--------|-------------|
| **Search** | Debounced (500ms), local-first, stale-response protected, search history with auto-suggestions, offline fallback across all cached products. |
| **Shipping Info** | Address selection/management with Standard/Express/Store Pickup options. |
| **Checkout** | Payment method selection with order summary breakdown. |
| **Order Confirmation** | Animated confirmation with order details. |
| **Profile / Settings** | Theme toggle (Light/Dark), language toggle (AR/EN). |

---

## Edge Cases Handled

| Case | Handling |
|------|---------|
| No internet | Offline indicator banner, custom toast, cached data served, auto-retry on reconnect |
| Empty product list | Dedicated empty state widget |
| API failure | `Either<Failure, T>` error model, error widgets with retry callback |
| Duplicate cart items | Quantity increment instead of duplicate entry |
| Quantity < 1 | Decrement button disabled at 1; further decrement triggers removal |
| App restart with cart | Hive persistence, cart loaded on app init |

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter (SDK ^3.10.0) |
| State Management | Cubit (`flutter_bloc`) |
| Local Storage | Hive (`hive_flutter`) |
| Networking | Dio |
| DI | GetIt |
| Error Handling | dartz (`Either<Failure, T>`) |
| Image Caching | cached_network_image |
| Loading Effects | shimmer |
| Connectivity | connectivity_plus |
| Localization | Custom (230+ AR/EN strings) |
| Testing | flutter_test, bloc_test, mocktail |

---

## Testing

```bash
flutter test
```

| Suite | Coverage |
|-------|----------|
| `ProductsCubit` | Initial state, load success, load failure |
| `SearchCubit` | Search flow, debounce, empty results |
| `CartCubit` | Add, remove, increment, decrement, clear, persistence |
| `CartRepositoryImpl` | Repository implementation tests |
| `ProductsRepositoryImpl` | Repository with cache + remote tests |
| `CategoryRepositoryImpl` | Category fetching tests |
| `SearchHistoryRepositoryImpl` | History CRUD tests |
| `GetProductsUseCase` | UseCase execution tests |
| Entity Tests | Equatable, computed properties |
| Model Tests | JSON serialization, toEntity conversion |
| Core Tests | Failures, ConnectivityCubit |
| Widget Tests | App initialization smoke test |

**18 test files** covering domain, data, presentation, and core layers.

---

## Documentation

| Document | Path |
|----------|------|
| Product Requirements | [`docs/PRD.md`](docs/PRD.md) |
| Software Requirements | [`docs/SRS.md`](docs/SRS.md) |
| Architecture | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) |
| Sequence Diagrams | [`docs/SEQUENCE_DIAGRAM.md`](docs/SEQUENCE_DIAGRAM.md) |

---

## Getting Started

```bash
git clone https://github.com/devhakeem5/mini-ecommerce-app.git
cd mini_commerce_app
flutter pub get
flutter run
flutter test
```
