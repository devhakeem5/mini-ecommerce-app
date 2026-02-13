# Product Requirements Document (PRD)

## Mini Commerce App — v1.0.1

---

## 1. Product Vision

Mini Commerce is a Flutter-based mobile commerce application designed to demonstrate production-grade engineering practices in a constrained scope. The product prioritizes **architectural integrity**, **offline resilience**, and **non-blocking UX patterns** over feature breadth. It serves as a reference implementation of Clean Architecture applied to a real-world e-commerce browsing and cart workflow.

---

## 2. Problem Statement

Most e-commerce app demos prioritize visual polish while neglecting the engineering challenges that define production quality: offline handling, data consistency under concurrent mutations, stale-data management, and clean separation of concerns. This project addresses these gaps by implementing:

- Cache-first browsing that never blocks on network.
- A concurrency-safe cart that survives race conditions from rapid user input.
- A search UX that eliminates stale responses through ID-based versioning.
- A functional error model (`Either<Failure, T>`) that replaces exception-driven control flow.

---

## 3. Target Users

| Persona | Description |
|---------|-------------|
| **Primary** | Technical reviewers evaluating Flutter architecture competency |
| **Secondary** | End-users browsing products on mobile/tablet/desktop with unreliable connectivity |

---

## 4. Scope

### In Scope

- Product browsing with paginated infinite scroll
- Product detail view with Hero transitions and variant selectors
- Persistent local cart with quantity management
- Debounced search with local-first strategy and search history
- Offline-first data access (Stale-While-Revalidate pattern)
- Real-time connectivity monitoring with offline indicator
- Fly-to-cart micro-interaction animation
- Bilingual support (Arabic / English) with RTL
- Light and Dark theme support
- Multi-step checkout flow (Shipping → Payment → Confirmation)
- Address management with default seeding

### API

- **DummyJSON Products API** (`https://dummyjson.com/products`)
- Endpoints consumed: `/products`, `/products/search`, `/products/category/{slug}`, `/products/categories`
- Pagination parameters: `limit`, `skip`

---

## 5. Explicit Non-Goals

| Non-Goal | Rationale |
|----------|-----------|
| Real authentication / user accounts | API is a dummy source; no auth endpoints consumed |
| Real payment processing | Checkout flow is UI-complete but does not submit orders |
| Push notifications | Out of scope for browsing + cart challenge |
| Product reviews / user-generated content | Not supported by DummyJSON |
| Server-side cart sync | Cart is local-only by design (Hive persistence) |
| Complex inventory management | `availabilityStatus` is displayed but not enforced beyond out-of-stock UI gating |

---

## 6. Key Features

### 6.1 Home / Browse

- **Sections**: Promotions slider, category horizontal list, new arrivals, brands showcase, recommended products, blogs list.
- **Pagination**: Infinite scroll with 20-item pages, ID-based deduplication (`_dedup` in `ProductsCubit`), `hasReachedMax` detection.
- **Offline**: Hive-cached pages served instantly on launch. Remote fetch runs in background. UI never blocks.
- **Skeleton loaders**: Shimmer placeholders during initial load.
- **Auto-retry on reconnect**: `ConnectivityCubit` state changes trigger `loadMoreProducts()` retry when pagination previously failed.

### 6.2 Product Details

- Hero shared-element transition on product thumbnail.
- Image gallery with `CachedNetworkImage`.
- Star rating display.
- Category-aware variant selectors: Size options for clothing, RAM/Storage for electronics (`ProductOptionConfig`).
- Description shown via bottom sheet.
- Related products section.
- Fly-to-cart animation triggered from "Add to Cart" action.
- Out-of-stock products: "Add to Cart" is disabled with Arabic toast notification (case-insensitive `availabilityStatus` check).

### 6.3 Cart

- Persistent via Hive. Survives app restart and offline mode.
- Quantity increment/decrement with minimum quantity of 1.
- Swipe-to-delete with 5-second undo grace period (`undoRemoveItem` restores item and original quantity).
- Subtotal, discount, and total calculations in domain entity (`Cart.totalPrice`, `Cart.totalDiscountedPrice`, `Cart.totalSavings`).
- Price synchronization: When `ProductsCubit` emits `ProductsLoaded`, a `BlocListener` in `main.dart` triggers `CartCubit.syncPrices()` to update cart item prices from fresh server data.
- Clear cart with confirmation dialog.

### 6.4 Search

- **Debounce**: 500ms timer in `SearchCubit.onSearchChanged()`.
- **Local-first**: On search trigger, local DB is searched first (`searchProductsLocallyUseCase`). Local results are emitted immediately.
- **Remote sync**: API search runs in parallel. Remote results replace local results via `SearchResultsLoaded` state emission.
- **Stale-response protection**: `_searchId` integer incremented on each new search. All async callbacks validate `currentSearchId == _searchId` before emitting state. This prevents out-of-order responses from overwriting newer results.
- **Search history**: Persisted via `SearchHistoryLocalDataSource` (Hive). Auto-suggestions filtered from history during typing.
- **Offline fallback**: When API fails, `ProductsRepositoryImpl` searches all locally cached products (`searchLocalProducts`) across all cache keys.
- **Pagination**: Search results support infinite scroll with deduplication.

### 6.5 Connectivity Monitoring

- `ConnectivityCubit` subscribes to `ConnectivityService.onConnectivityChanged` stream.
- Offline → Online transition triggers `OfflineSyncService.syncPendingActions()`.
- `CustomToast` notifications on connectivity state changes (warning on disconnect, success on reconnect).
- `OfflineIndicator` banner conditionally shown in Home and Search pages.

### 6.6 Fly-to-Cart Animation

- Custom overlay-based animation system.
- `FlyToCartController` (InheritedWidget) provides `FlyToCartControllerState` down the widget tree.
- `FlyingItem` captures start position and product thumbnail URL.
- `FlyToCartOverlay` creates `OverlayEntry` widgets that animate along a **quadratic Bézier curve** (`_quadraticBezier`) from product card to cart icon.
- Animation: 600ms duration, `easeInOutCubic` curve, scale reduction (1.0 → 0.3), opacity fade.
- On completion: triggers `bounceNotifier` for cart icon bounce feedback.

### 6.7 Localization

- Full Arabic/English translations in `AppLocalizations` (230+ translation strings).
- `LocaleCubit` with `GetLocaleUseCase` / `SetLocaleUseCase` for persisted language preference.
- `BuildContextTranslationExtension` provides `context.tr('key')` convenience.
- RTL layout support via Flutter's built-in `GlobalWidgetsLocalizations.delegate`.

### 6.8 Theming

- `AppTheme.lightTheme` and `AppTheme.darkTheme` defined in `core/theme/`.
- `AppColors` provides the design system color palette.
- `ThemeMode.system` used by default — follows device preference.
- Premium design: Electric Lime accent, glassmorphism card effects.

---

## 7. User Stories

| ID | Story | Acceptance Criteria |
|----|-------|-------------------|
| US-1 | As a user, I want to browse products instantly when I open the app, even without internet. | Cached products from Hive load first. Remote data fetched in background. UI never shows a blocking spinner for cached data. |
| US-2 | As a user, I want to scroll through products infinitely without seeing duplicates. | Each page appends 20 items. `_dedup()` filters by product ID. `hasReachedMax` stops further requests when response < page size. |
| US-3 | As a user, I want to add products to my cart with a satisfying visual feedback. | Tapping "Add to Cart" launches fly-to-cart animation (product image arcs toward basket icon). Cart icon bounces on arrival. No modal dialog interrupts the flow. |
| US-4 | As a user, I want my cart to be exactly as I left it after restarting the app. | Cart serialized to Hive as `List<Map>`. Loaded on app init via `CartCubit.loadCart()`. Quantities and calculated totals preserved. |
| US-5 | As a user, I want search results to appear quickly without typing every character triggering an API call. | 500ms debounce timer. Local results shown immediately. Remote results replace local on arrival. Stale responses discarded via `_searchId` check. |
| US-6 | As a user, I want to undo accidental cart item deletions. | Swipe-to-delete shows SnackBar with "Undo" action. 5-second window. `undoRemoveItem()` restores item with original quantity. |
| US-7 | As a user, I want to know when I'm offline and still be able to use the app. | `OfflineIndicator` banner displayed. Custom toast on connectivity change. All cached data accessible. Pagination retries automatically on reconnect. |
| US-8 | As a user, I want cart prices to reflect the latest server data. | `syncPrices()` triggered when `ProductsLoaded` state emits. `updateProductPrices()` compares and updates only changed prices in Hive. |

---

## 8. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| First meaningful paint (cached data) | < 500ms | Time from app launch to first product card rendered from cache |
| Search debounce timing | 500ms | Timer duration in `SearchCubit.onSearchChanged()` |
| Fly-to-cart animation duration | 600ms | `AnimationController` duration in `_FlyingWidgetState` |
| Cart operation concurrency safety | Zero race conditions | Sequential queue (`_processingQueue`) serializes all cart mutations |
| Stale search response rate | 0% | `_searchId` versioning guarantees only latest search emits state |
| Offline data availability | 100% of cached pages | All previously fetched product pages and search results available offline |

---

## 9. Offline-First Reasoning

The offline-first strategy is not an afterthought — it is a structural decision embedded in the repository layer:

1. **`ProductsRepositoryImpl._fetchProductsStream()`** always reads from `local.getCachedProducts()` first, yielding a `ProductsResult(isOffline: true)` if cache exists.
2. Only then does it attempt a remote fetch. If remote succeeds, cache is updated and a second `ProductsResult(isOffline: false)` is yielded.
3. If remote fails and a cached result was already yielded, the user sees no error — they continue with stale-but-available data.
4. If remote fails and no cache exists, `NetworkFailure` is emitted.

This is a **Stale-While-Revalidate** pattern: the user always gets the fastest possible response (cache), while the system transparently refreshes data in the background.

---

## 10. Why Fly-to-Cart Instead of Modal Confirmation

| Aspect | Modal Dialog | Fly-to-Cart Animation |
|--------|-------------|----------------------|
| **User flow interruption** | Blocks interaction until dismissed | Non-blocking; user can continue browsing immediately |
| **Cognitive load** | Requires decision (confirm/cancel) | No decision required — visual feedback confirms action implicitly |
| **Engagement** | Static, utilitarian | Dynamic micro-interaction increases perceived quality |
| **Error recovery** | Must handle cancel state | N/A — cart state is committed, undo available from cart page |
| **Time cost** | Minimum ~1s for user to read + tap | 600ms animation runs concurrently with continued browsing |

The fly-to-cart pattern was chosen because it provides **non-blocking confirmation**. The user sees the product thumbnail physically move to the cart icon, which is a stronger spatial cue than a text dialog. The animation does not require the user to stop, read, and confirm — it runs as a side effect of their tap, allowing them to immediately add another product or navigate elsewhere.

This is a deliberate UX trade-off: reducing friction at the cost of forgoing a confirmation step. The cart page provides full undo capability (`undoRemoveItem`) as a safety net.
