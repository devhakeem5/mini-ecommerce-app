# Mini Commerce App

A production-style Flutter mini commerce app focused on **offline-first data consistency**, **concurrency-safe cart mutations**, and **strict Clean Architecture boundaries**. While limited in scope as a take-home challenge, it is implemented with the rigor of a production system.

**API**: [DummyJSON Products](https://dummyjson.com/products) — pagination, search, and category endpoints.

---

## Engineering Highlights

| Area | Implementation |
|------|---------------|
| **Clean Architecture** | Strict 3-layer separation: `domain/` (entities, use cases, repo interfaces) → `data/` (repo implementations, data sources, models) → `presentation/` (cubits, pages, widgets). Domain has zero framework dependencies. |
| **Offline-First Data** | Stale-While-Revalidate pattern in `ProductsRepositoryImpl`: cache is read first and yielded immediately, remote fetch runs in background, UI updates transparently. User never blocks on network. |
| **Concurrency-Safe Cart** | Sequential queue (`_processingQueue`) in `CartRepositoryImpl` serializes all cart mutations. Prevents race conditions from rapid add/remove operations without requiring database transactions. |
| **Non-Blocking Cart UX** | Fly-to-cart animation implemented as an isolated **OverlayEntry** to prevent widget tree rebuilds during animation and maintain uninterrupted browsing flow. Avoids blocking dialogs entirely. |
| **Search Integrity** | 500ms debounce with local-first strategy. Previous search stream subscription is cancelled (`_cancelSearch()`) before each new query, preventing stale API responses from overwriting newer results. Combined with `isClosed` guards before every emit. |
| **Functional Error Model** | `dartz` `Either<Failure, T>` across all repository boundaries. Three failure types: `ServerFailure`, `CacheFailure`, `NetworkFailure`. No unchecked exceptions cross layer boundaries. |
| **Price Synchronization** | Non-destructive synchronization ensures cart state remains visible during product refresh cycles. Only changed prices are persisted to Hive and re-emitted to UI. |
| **Logic Separation** | UI components depend strictly on Domain Layer UseCases for business logic (e.g., product filtering, option configuration). No business logic leaks into Widgets or Pages. |

---

## Architecture

```
lib/
├── core/           → DI (GetIt), Error types, Localization (AR/EN), Connectivity, Theme, Hive init
├── domain/         → Multiple entities and use cases organized per feature boundary (zero framework deps)
├── data/           → Repository implementations, Local (Hive) + Remote (Dio) Data Sources, Models
└── presentation/   → Feature-first: products/ cart/ profile/ common/
```

**Data Flow**: `UI → Cubit → UseCase → Repository Interface (Domain) → Repository Impl (Data) → Local/Remote DataSource`

**Design Trade-offs**:
- `syncPrices` orchestrator placed at application layer (`main.dart`) for simplicity instead of introducing a complex domain event bus.
- Hive used over SQLite for simplicity; strict sequential queue implemented in code to mitigate lack of ACID transactions.

**Performance Note**: Optimized to minimize rebuilds using localized `BlocBuilder` scopes and `const` widgets throughout the widget tree.

---

## Screens

### Mandatory

| Screen | Key Features |
|--------|-------------|
| **Home / Browse** | Promotions slider, categories, brands, new arrivals, recommended. Infinite scroll (20/page). Cached data instant on launch. Auto-retry pagination on reconnect. |
| **Product Details** | Hero transition, image gallery, star rating, category-aware variant selectors, description bottom sheet, related products. Out-of-stock gating. |
| **Cart** | Hive-persisted. Quantity controls (min 1). Swipe-to-delete with 5s undo. Subtotal lookup in domain entity. Price sync on product load. |

### Optional

| Screen | Description |
|--------|-------------|
| **Search** | Debounced (500ms), local-first, stale-response protected, search history, offline fallback. |
| **Shipping & Checkout** | Address management and payment selection UI (demonstration only). |
| **Settings** | Theme toggle (Light/Dark), language toggle (AR/EN). |

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
| Testing | flutter_test, bloc_test, mocktail |

---

## Testing

```bash
flutter test
```

**Philosophy**: Business-critical logic (cart concurrency, search race conditions, pagination merging, price sync) is covered with unit tests. UI logic is tested via widget smoke tests.

| Suite | Focus Area |
|-------|------------|
| `ProductsCubit` | Initial state, load success, load failure, deduplication |
| `SearchCubit` | Search flow, debounce, stale response rejection |
| `CartCubit` | Add, remove, increment, decrement, persistence, price sync |
| `CartRepository` | Queue serialization, Hive interaction |
| `ProductsRepository` | Stale-While-Revalidate caching strategy |
| `UseCases` | Pure domain logic execution |

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
