# Mini Commerce App 🛍️

A premium Flutter e-commerce application built with **Clean Architecture**, **Cubit State Management**, and an **Offline-First** strategy. The app delivers a seamless, production-grade shopping experience with a focus on architecture quality, performance, and polished UX.

**API**: [DummyJSON Products API](https://dummyjson.com/products) — supports pagination, search, and category filtering.

---

## 📱 Screens

### Mandatory Screens

| Screen | Description |
|--------|-------------|
| **Home / Browse** | Rich product catalog with categories, promotions slider, brands, new arrivals, and recommended sections. Infinite scroll pagination with skeleton loaders. Cached data appears instantly on launch. |
| **Product Details** | Immersive gallery with Hero transitions, star ratings, variant selectors (Size/RAM/Storage based on category), description bottom sheet, and related products. |
| **Cart** | Persistent cart with quantity controls (min 1), swipe-to-delete with 5-second undo grace period, subtotal/discount/total calculations, and price sync with server. |

### Optional Screens (Bonus)

| Screen | Description |
|--------|-------------|
| **Search** | Debounced search (300ms) with auto-suggestions, recent search history, and offline search fallback through cached products. |
| **Shipping Info** | Address selection/management with shipping method options (Standard, Express, Store Pickup). |
| **Checkout** | Payment method selection with order summary breakdown and discount display. |
| **Order Confirmation** | Animated confirmation with order details and continue shopping flow. |
| **Profile / Settings** | Theme toggle (Light/Dark), language toggle (Arabic/English), account settings. |

---

## ✅ Challenge Requirements — Implementation Status

### Core Problems Solved

| Requirement | Status | Implementation Details |
|------------|--------|----------------------|
| **Offline-First Browse** | ✅ | Products cached locally via Hive. Cached data loads instantly on app start. Subtle offline indicator banner appears on connectivity loss. UI never blocks waiting for network. |
| **Cart Persistence** | ✅ | Cart stored in Hive. Survives app restarts and works fully offline. Quantities, totals, and discounts remain correct. Price sync with server on reconnect. |
| **Fast Search UX** | ✅ | 300ms debounce. Cached results appear immediately. Local-first strategy: searches local DB first, then syncs with API. Offline fallback searches through all cached products. Empty results and API errors handled gracefully. |

### Architecture (REQUIRED)

| Requirement | Status | Details |
|------------|--------|--------|
| **Clean Architecture** | ✅ | Strict 3-layer separation: `domain/` → `data/` → `presentation/` |
| **Repository Pattern** | ✅ | 7 repository interfaces in domain, implemented in data layer |
| **Dependency Injection** | ✅ | Centralized DI using `GetIt` via `service_locator.dart` |
| **Separation of Concerns** | ✅ | 20 Use Cases, 7 Entities, dedicated Cubits per feature |
| **State Management** | ✅ | Cubit (Bloc) pattern with `Equatable` states |

### Performance & UX (REQUIRED)

| Requirement | Status | Details |
|------------|--------|--------|
| **Pagination** | ✅ | Infinite scroll with deduplication, end-of-list detection, offline-aware retry |
| **Skeleton Loaders** | ✅ | Shimmer effect for product grids, horizontal lists, and detail pages |
| **Image Caching** | ✅ | `cached_network_image` for optimized loading and scroll performance |
| **Avoid Unnecessary Rebuilds** | ✅ | Targeted `BlocBuilder`/`BlocListener` usage, `Equatable` states |

### Animations (REQUIRED)

| Requirement | Status | Details |
|------------|--------|--------|
| **Product → Details Transition** | ✅ | Hero shared element animation on product image |
| **Add-to-Cart Micro Interaction** | ✅ | Custom fly-to-cart animation with product image flying to basket icon |

### Edge Cases (REQUIRED)

| Edge Case | Status | Handling |
|-----------|--------|----------|
| **No Internet** | ✅ | Offline indicator, custom toast notifications, cached data served, auto-retry on reconnect |
| **Empty Product List** | ✅ | Dedicated empty state widget |
| **API Failure** | ✅ | `Either<Failure, T>` error handling via `dartz`, error widgets with retry |
| **Duplicate Cart Items** | ✅ | Quantity increment instead of duplicate entry |
| **Quantity < 1** | ✅ | Decrement button disabled at quantity 1 |
| **App Restart with Cart** | ✅ | Hive persistence, cart loaded on app init |

### Bonus Items

| Bonus | Status | Details |
|-------|--------|--------|
| **Unit Tests** | ✅ | Cart logic, Products Cubit, Search Cubit, Repository, UseCase tests (18 tests) |
| **Widget Tests** | ✅ | Smoke test for app initialization |

---

## 🌟 Beyond Requirements — Extra Features

These features were **not required** by the challenge but were implemented to demonstrate production-quality engineering:

| Feature | Description |
|---------|-------------|
| **Dynamic Theming** | Full Light & Dark mode support with a premium design system (Electric Lime accent, glassmorphism cards) |
| **Bilingual (AR/EN)** | Complete Arabic and English localization with RTL support and in-app language toggle |
| **Fly-to-Cart Animation** | Custom particle animation showing the product image flying into the cart basket |
| **Responsive Design** | Fluid layouts adapting to Mobile, Tablet, and Desktop screen sizes |
| **Undo Delete** | 5-second grace period to undo cart item removal via SnackBar action |
| **Connectivity Monitoring** | Real-time connection tracking with `ConnectivityCubit`, custom toast notifications on connection change |
| **Auto-Retry on Reconnect** | Pagination automatically retries failed requests when connectivity is restored |
| **Price Sync** | Cart prices synchronized with server data to prevent stale pricing |
| **Search History** | Persistent search history with auto-suggestions |
| **Variant Selectors** | Category-aware variant options (Size for clothing, RAM/Storage for electronics) |
| **Multi-Step Checkout** | Professional Shipping → Payment → Confirmation flow following e-commerce best practices |
| **Functional Error Handling** | `dartz` `Either<Failure, T>` pattern for predictable, composable error management |
| **Rich Home Screen** | Promotions slider, category horizontals, brands showcase, new arrivals, recommended sections |
| **Address Management** | Multiple shipping addresses with selection bottom sheet |

---

## 🏗️ Architecture

```
lib/
├── core/                          # Shared infrastructure
│   ├── di/                        # GetIt dependency injection
│   ├── error/                     # Failure classes (ServerFailure, CacheFailure)
│   ├── localization/              # AR/EN translations
│   ├── network/                   # Dio client, ConnectivityCubit
│   ├── storage/                   # Hive initialization
│   ├── theme/                     # AppTheme, AppColors (Light + Dark)
│   └── util/                      # Responsive helpers
│
├── domain/                        # Business logic (zero dependencies)
│   ├── entities/                  # Product, Cart, CartItem, Category, Address, User
│   ├── repositories/              # Abstract interfaces (7 repositories)
│   └── usecases/                  # Single-responsibility use cases (20 use cases)
│       ├── products/              # GetProducts, GetByCategory, Search, GetNew, GetRecommended
│       ├── cart/                  # Add, Remove, Load, Update, Clear
│       ├── search/                # SearchProducts, GetHistory, SaveHistory, ClearHistory
│       ├── address/               # GetAddresses, SelectAddress, SeedDefaults
│       └── locale/                # GetLocale, SaveLocale
│
├── data/                          # Implementation layer
│   ├── datasources/
│   │   ├── local/                 # Hive: Products, Cart, Search History, Address, Locale
│   │   └── remote/                # Dio: Products API
│   ├── models/                    # JSON serialization models
│   └── repositories/              # Repository implementations (7 repos)
│
└── presentation/                  # UI layer
    ├── products/                  # Home, AllProducts, ProductDetails, Search
    │   ├── cubit/                 # ProductsCubit, ProductListCubit, SearchCubit, CategoriesCubit
    │   ├── pages/
    │   └── widgets/               # ProductCard, CategoryList, PromotionsSlider, etc.
    ├── cart/                      # Cart, Shipping, Checkout, OrderConfirmation
    │   ├── cubit/                 # CartCubit, AddressCubit
    │   ├── pages/
    │   └── widgets/
    ├── profile/                   # Profile/Settings
    │   └── cubit/                 # ProfileCubit, LocaleCubit
    └── common/                    # Shared widgets
        ├── fly_to_cart/           # Fly-to-cart animation system
        ├── visual_cart/           # Visual cart overlay
        └── widgets/               # OfflineIndicator, SkeletonLoaders, CustomToast, etc.
```

### Data Flow

```
UI (Cubit) → UseCase → Repository Interface (Domain)
                              ↓
                    Repository Implementation (Data)
                         ↙         ↘
              Local DataSource    Remote DataSource
                 (Hive)              (Dio API)
```

**Offline-First Strategy**: Repository checks local cache first → returns cached data immediately → fetches from API in background → updates cache → emits updated data via Stream.

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.x |
| **State Management** | Bloc / Cubit (`flutter_bloc`) |
| **Local Storage** | Hive (`hive_flutter`) |
| **Networking** | Dio |
| **DI** | GetIt |
| **Error Handling** | dartz (`Either<Failure, T>`) |
| **Image Caching** | cached_network_image |
| **Loading Effects** | shimmer |
| **Connectivity** | connectivity_plus |
| **Testing** | flutter_test, bloc_test, mocktail |

---

## 🧪 Testing

```bash
flutter test
```

| Test Suite | Coverage |
|-----------|----------|
| `ProductsCubit` | Initial state, load success, load failure |
| `SearchCubit` | Search flow, debounce, empty results |
| `CartCubit` | Add, remove, increment, decrement, clear, persistence |
| `CartRepositoryImpl` | Repository implementation tests |
| `GetProductsUseCase` | UseCase execution tests |
| Widget Tests | App initialization smoke test |

**Total: 18 tests passing ✅**

---

## 🚀 Getting Started

```bash
# Clone the repository
git clone <repository-url>
cd mini_commerce_app

# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze
```
