# Sequence Diagrams

## Mini Commerce App — v1.0.1

---

## A. Add-to-Cart Flow (Concurrency-Safe)

This is the **mandatory** flow demonstrating how adding a product to the cart traverses all architectural layers with concurrency safety.

### Sequence

```
User                UI (ProductDetailsPage)      CartCubit          AddToCartUseCase      CartRepositoryImpl        Sequential Queue       CartLocalDataSource (Hive)
 │                        │                         │                      │                      │                        │                       │
 │  Tap "Add to Cart"     │                         │                      │                      │                        │                       │
 │───────────────────────>│                         │                      │                      │                        │                       │
 │                        │                         │                      │                      │                        │                       │
 │                        │  addToCart(product)      │                      │                      │                        │                       │
 │                        │────────────────────────>│                      │                      │                        │                       │
 │                        │                         │                      │                      │                        │                       │
 │                        │                         │  call(product)       │                      │                        │                       │
 │                        │                         │─────────────────────>│                      │                        │                       │
 │                        │                         │                      │                      │                        │                       │
 │                        │                         │                      │  addToCart(product)   │                        │                       │
 │                        │                         │                      │─────────────────────>│                        │                       │
 │                        │                         │                      │                      │                        │                       │
 │                        │                         │                      │                      │  _enqueue(task)         │                       │
 │                        │                         │                      │                      │───────────────────────>│                       │
 │                        │                         │                      │                      │                        │                       │
 │                        │                         │                      │                      │                        │  Wait for previous     │
 │                        │                         │                      │                      │                        │  tasks to complete     │
 │                        │                         │                      │                      │                        │  (...queue drain...)   │
 │                        │                         │                      │                      │                        │                       │
 │                        │                         │                      │                      │                        │  Execute task:         │
 │                        │                         │                      │                      │                        │                       │
 │                        │                         │                      │                      │                        │  loadCart()            │
 │                        │                         │                      │                      │                        │──────────────────────>│
 │                        │                         │                      │                      │                        │                       │
 │                        │                         │                      │                      │                        │  List<Map> rawItems    │
 │                        │                         │                      │                      │                        │<──────────────────────│
 │                        │                         │                      │                      │                        │                       │
 │                        │                         │                      │                      │                        │  Check if product      │
 │                        │                         │                      │                      │                        │  exists (indexWhere)   │
 │                        │                         │                      │                      │                        │                       │
 │                        │                         │                      │                      │                        │  IF EXISTS:            │
 │                        │                         │                      │                      │                        │    quantity += 1       │
 │                        │                         │                      │                      │                        │  ELSE:                 │
 │                        │                         │                      │                      │                        │    add new CartItem    │
 │                        │                         │                      │                      │                        │    with quantity = 1   │
 │                        │                         │                      │                      │                        │                       │
 │                        │                         │                      │                      │                        │  saveCart(maps)        │
 │                        │                         │                      │                      │                        │──────────────────────>│
 │                        │                         │                      │                      │                        │                       │
 │                        │                         │                      │                      │                        │  Hive write complete   │
 │                        │                         │                      │                      │                        │<──────────────────────│
 │                        │                         │                      │                      │                        │                       │
 │                        │                         │                      │  Right(null)         │  Complete future        │                       │
 │                        │                         │                      │<─────────────────────│<───────────────────────│                       │
 │                        │                         │                      │                      │                        │                       │
 │                        │                         │  Either<Failure,void>│                      │                        │                       │
 │                        │                         │<─────────────────────│                      │                        │                       │
 │                        │                         │                      │                      │                        │                       │
 │                        │                         │  fold(onFailure, onSuccess)                 │                        │                       │
 │                        │                         │  onSuccess:                                 │                        │                       │
 │                        │                         │    loadCartUseCase() → loadCart()            │                        │                       │
 │                        │                         │    → Right(List<CartItem>)                  │                        │                       │
 │                        │                         │                      │                      │                        │                       │
 │                        │                         │  emit(CartLoaded(cart: Cart(items)))         │                        │                       │
 │                        │                         │─────────────────────────────────────────────────────────────────────────────────────────────────>
 │                        │                         │                      │                      │                        │                       │
 │                        │  BlocBuilder rebuilds    │                      │                      │                        │                       │
 │                        │  with new cart state     │                      │                      │                        │                       │
 │                        │<────────────────────────│                      │                      │                        │                       │
 │                        │                         │                      │                      │                        │                       │
 │  Cart badge updates    │                         │                      │                      │                        │                       │
 │  Fly-to-cart animation │                         │                      │                      │                        │                       │
 │<───────────────────────│                         │                      │                      │                        │                       │
```

### Why This Flow Guarantees Consistency

1. **Sequential Queue**: `_enqueue()` chains all cart operations onto `_processingQueue`. Even if `addToCart` is called 5 times in rapid succession, each invocation waits for the previous one to complete before reading the current cart state.

2. **Read-Modify-Write Atomicity**: Within each enqueued task, the current cart is loaded from Hive (`_loadModels()`), modified in memory (duplicate check + quantity increment or new item), then saved back (`_saveModels()`). Because the queue serializes execution, no other operation can interleave between the read and write.

3. **Either Result Propagation**: If any step fails (Hive read/write error), the exception is caught and wrapped in `Left(CacheFailure)`. The `Completer` receives the error, and the Cubit emits `CartError`. The queue continues processing subsequent tasks.

4. **State Re-emission**: After a successful write, `CartCubit` calls `loadCartUseCase()` to get the freshest state from Hive and emits `CartLoaded`. This ensures the UI always reflects the persisted state, not an optimistic in-memory prediction.

---

## B. Product Load Flow (Offline-First / Stale-While-Revalidate)

This flow demonstrates the cache-first loading strategy that enables instant rendering of cached data while transparently refreshing from the network.

### Sequence

```
User          UI (HomePage)       ProductsCubit       GetProductsUseCase     ProductsRepositoryImpl    ProductsLocalDS (Hive)    ProductsRemoteDS (Dio)
 │                 │                    │                      │                       │                       │                        │
 │  Open app       │                    │                      │                       │                       │                        │
 │────────────────>│                    │                      │                       │                       │                        │
 │                 │                    │                      │                       │                       │                        │
 │                 │  loadInitial       │                      │                       │                       │                        │
 │                 │  Products()        │                      │                       │                       │                        │
 │                 │───────────────────>│                      │                       │                       │                        │
 │                 │                    │                      │                       │                       │                        │
 │                 │                    │  emit(ProductsLoading)                       │                       │                        │
 │                 │<───────────────────│                      │                       │                       │                        │
 │                 │                    │                      │                       │                       │                        │
 │  Skeleton       │                    │  call(limit:20,      │                       │                       │                        │
 │  loaders shown  │                    │       skip:0)        │                       │                       │                        │
 │<────────────────│                    │─────────────────────>│                       │                       │                        │
 │                 │                    │                      │                       │                       │                        │
 │                 │                    │                      │  getProducts(         │                       │                        │
 │                 │                    │                      │    limit, skip)       │                       │                        │
 │                 │                    │                      │──────────────────────>│                       │                        │
 │                 │                    │                      │                       │                       │                        │
 │                 │                    │                      │                       │  getCachedProducts(   │                        │
 │                 │                    │                      │                       │    cacheKey)           │                        │
 │                 │                    │                      │                       │──────────────────────>│                        │
 │                 │                    │                      │                       │                       │                        │
 │                 │                    │                      │                       │  List<Map>? cached    │                        │
 │                 │                    │                      │                       │<──────────────────────│                        │
 │                 │                    │                      │                       │                       │                        │
 │                 │                    │                      │   ┌─── IF CACHE HIT ──┐                       │                        │
 │                 │                    │                      │   │                   │                       │                        │
 │                 │                    │                      │  yield Right(         │                       │                        │
 │                 │                    │                      │    ProductsResult(    │                       │                        │
 │                 │                    │                      │      products,        │                       │                        │
 │                 │                    │  Stream yields        │      isOffline:true)) │                       │                        │
 │                 │                    │  Either(cached)       │   │                   │                       │                        │
 │                 │                    │<─────────────────────│<──┘                   │                       │                        │
 │                 │                    │                      │                       │                       │                        │
 │                 │                    │  _dedup() +          │                       │                       │                        │
 │                 │                    │  emit(ProductsLoaded │                       │                       │                        │
 │                 │                    │    isOffline: true)   │                       │                       │                        │
 │                 │<───────────────────│                      │                       │                       │                        │
 │                 │                    │                      │                       │                       │                        │
 │  INSTANT:       │                    │                      │                       │                       │                        │
 │  Cached         │                    │                      │                       │  getProducts(         │                        │
 │  products       │                    │                      │                       │    limit, skip)       │                        │
 │  rendered       │                    │                      │                       │──────────────────────────────────────────────>│
 │<────────────────│                    │                      │                       │                       │                        │
 │                 │                    │                      │                       │                       │  API Response           │
 │                 │                    │                      │                       │                       │  List<ProductModel>     │
 │                 │                    │                      │                       │<──────────────────────────────────────────────│
 │                 │                    │                      │                       │                       │                        │
 │                 │                    │                      │                       │  cacheProducts(       │                        │
 │                 │                    │                      │                       │    cacheKey, models)  │                        │
 │                 │                    │                      │                       │──────────────────────>│                        │
 │                 │                    │                      │                       │                       │                        │
 │                 │                    │                      │                       │  Cache updated        │                        │
 │                 │                    │                      │                       │<──────────────────────│                        │
 │                 │                    │                      │                       │                       │                        │
 │                 │                    │                      │  yield Right(         │                       │                        │
 │                 │                    │                      │    ProductsResult(    │                       │                        │
 │                 │                    │  Stream yields        │      products,        │                       │                        │
 │                 │                    │  Either(fresh)        │      isOffline:false)) │                       │                        │
 │                 │                    │<─────────────────────│<──────────────────────│                       │                        │
 │                 │                    │                      │                       │                       │                        │
 │                 │                    │  _dedup() +          │                       │                       │                        │
 │                 │                    │  emit(ProductsLoaded │                       │                       │                        │
 │                 │                    │    isOffline: false)  │                       │                       │                        │
 │                 │<───────────────────│                      │                       │                       │                        │
 │                 │                    │                      │                       │                       │                        │
 │  UPDATED:       │                    │                      │                       │                       │                        │
 │  Fresh data     │                    │                      │                       │                       │                        │
 │  replaces cache │                    │                      │                       │                       │                        │
 │<────────────────│                    │                      │                       │                       │                        │
 │                 │                    │                      │                       │                       │                        │
 │                 │  BlocListener in main.dart                │                       │                       │                        │
 │                 │  detects ProductsLoaded                   │                       │                       │                        │
 │                 │  → CartCubit.syncPrices(products)         │                       │                       │                        │
 │                 │──────────────────────────────────────────────────────────────────────────────────────────────────────────────────>
```

### Stale-While-Revalidate Strategy Explained

The pattern has two critical properties:

1. **Stale data is served immediately**: The user sees products within the first frame after cache read completes (typically < 100ms for Hive). This eliminates the perceived latency of a network request.

2. **Revalidation happens silently**: The remote fetch runs in the background. If it succeeds, the UI is seamlessly updated with fresh data. If it fails (offline, timeout, server error), the user continues with cached data — no error is shown because cached data was already rendered.

**Offline scenario**: When the app is offline:
- Cache hit → products rendered immediately.
- Remote fetch fails → silently absorbed. User sees no error.
- `isOffline: true` flag allows the UI to optionally show an offline indicator.

**No cache, no network scenario**: When both cache is empty and network is unavailable:
- No cache hit → nothing yielded from step 1.
- Remote fetch fails → `Left(NetworkFailure())` yielded.
- `ProductsCubit` emits `ProductsError(message: 'no_internet_no_data')`.
- UI shows error state with retry button.

---

## C. Search Flow (Debounced + Local-First + Stale-Response Protection)

### Sequence

```
User        SearchPage       SearchCubit                  Timer         SearchProductsLocallyUseCase    SearchProductsUseCase    ProductsRepositoryImpl
 │               │                │                         │                     │                            │                        │
 │  Type "phone" │                │                         │                     │                            │                        │
 │──────────────>│                │                         │                     │                            │                        │
 │               │                │                         │                     │                            │                        │
 │               │  onSearchChanged("phone")                │                     │                            │                        │
 │               │───────────────>│                         │                     │                            │                        │
 │               │                │                         │                     │                            │                        │
 │               │                │  Cancel previous timer  │                     │                            │                        │
 │               │                │────────────────────────>│                     │                            │                        │
 │               │                │                         │                     │                            │                        │
 │               │                │  Filter history for     │                     │                            │                        │
 │               │                │  suggestions matching   │                     │                            │                        │
 │               │                │  "phone"                │                     │                            │                        │
 │               │                │                         │                     │                            │                        │
 │               │                │  emit(SearchHistoryLoaded(                    │                            │                        │
 │               │                │    history, suggestions))│                     │                            │                        │
 │               │<───────────────│                         │                     │                            │                        │
 │               │                │                         │                     │                            │                        │
 │  Suggestions  │                │  Start 500ms timer      │                     │                            │                        │
 │  displayed    │                │────────────────────────>│                     │                            │                        │
 │<──────────────│                │                         │                     │                            │                        │
 │               │                │                         │                     │                            │                        │
 │               │                │           ┌─── 500ms ───┐                     │                            │                        │
 │               │                │           │             │                     │                            │                        │
 │               │                │  Timer fires:            │                     │                            │                        │
 │               │                │  search("phone")        │                     │                            │                        │
 │               │                │<────────────────────────│                     │                            │                        │
 │               │                │                         │                     │                            │                        │
 │               │                │  ++_searchId (→ e.g. 5) │                     │                            │                        │
 │               │                │                         │                     │                            │                        │
 │               │                │  emit(SearchLoading)    │                     │                            │                        │
 │               │<───────────────│                         │                     │                            │                        │
 │               │                │                         │                     │                            │                        │
 │               │                │  Save to history        │                     │                            │                        │
 │               │                │  (addToSearchHistoryUseCase)                  │                            │                        │
 │               │                │                         │                     │                            │                        │
 │               │                │  if (5 != _searchId) return ← STALE CHECK    │                            │                        │
 │               │                │                         │                     │                            │                        │
 │               │                │  searchProductsLocallyUseCase("phone")        │                            │                        │
 │               │                │─────────────────────────────────────────────>│                            │                        │
 │               │                │                         │                     │                            │                        │
 │               │                │  Right(ProductsResult(local results))         │                            │                        │
 │               │                │<─────────────────────────────────────────────│                            │                        │
 │               │                │                         │                     │                            │                        │
 │               │                │  if (!isClosed && 5 == _searchId              │                            │                        │
 │               │                │      && localResults.isNotEmpty)              │                            │                        │
 │               │                │  emit(SearchResultsLoaded(                    │                            │                        │
 │               │                │    products: localResults,                    │                            │                        │
 │               │                │    isOffline: true))     │                     │                            │                        │
 │               │<───────────────│                         │                     │                            │                        │
 │               │                │                         │                     │                            │                        │
 │  LOCAL results │                │  if (5 != _searchId) return ← STALE CHECK   │                            │                        │
 │  shown         │                │                         │                     │                            │                        │
 │  instantly     │                │  searchProductsUseCase(query, limit, skip)   │                            │                        │
 │<──────────────│                │─────────────────────────────────────────────────────────────────────────>│                        │
 │               │                │                         │                     │                            │                        │
 │               │                │                         │                     │                            │                        │
 │               │                │                  Stream: cache yield then remote yield                     │                        │
 │               │                │                         │                     │                            │                        │
 │               │                │  forEach result:        │                     │                            │                        │
 │               │                │  if (isClosed || 5 != _searchId) return ← STALE CHECK                     │                        │
 │               │                │                         │                     │                            │                        │
 │               │                │  result.fold:           │                     │                            │                        │
 │               │                │  emit(SearchResultsLoaded(                    │                            │                        │
 │               │                │    products: _dedup(remoteResults),            │                            │                        │
 │               │                │    isOffline: false,     │                     │                            │                        │
 │               │                │    hasReachedMax))       │                     │                            │                        │
 │               │<───────────────│                         │                     │                            │                        │
 │               │                │                         │                     │                            │                        │
 │  REMOTE results│                │                         │                     │                            │                        │
 │  replace local │                │                         │                     │                            │                        │
 │<──────────────│                │                         │                     │                            │                        │
```

### Stale-Response Protection Explained

The `_searchId` mechanism prevents a critical race condition:

**Scenario without protection**:
1. User types "phone" → Search A fires (slow network, takes 3 seconds).
2. User types "laptop" → Search B fires (fast network, returns in 500ms).
3. Search B results displayed correctly.
4. Search A results arrive 2.5 seconds later → **overwrites Search B results** with wrong data.

**With `_searchId` protection**:
1. Search A fires with `currentSearchId = 4`.
2. Search B fires with `currentSearchId = 5`. `_searchId` is now `5`.
3. Search B results arrive → `5 == _searchId` → emitted ✅.
4. Search A results arrive → `4 != _searchId` → **discarded** ✅.

This is an application of the **version-based staleness check** pattern. It is simple, requires no cancellation tokens or stream subscriptions, and is effective for any number of overlapping searches.

---

## D. Price Synchronization Flow

### Sequence

```
main.dart (BlocListener)       CartCubit          UpdateCartPricesUseCase    CartRepositoryImpl        CartLocalDataSource (Hive)
         │                         │                       │                       │                        │
         │  ProductsLoaded emitted │                       │                       │                        │
         │  (from ProductsCubit)   │                       │                       │                        │
         │                         │                       │                       │                        │
         │  syncPrices(products)   │                       │                       │                        │
         │────────────────────────>│                       │                       │                        │
         │                         │                       │                       │                        │
         │                         │  if state is not      │                       │                        │
         │                         │  CartLoaded → return  │                       │                        │
         │                         │                       │                       │                        │
         │                         │  call(products)       │                       │                        │
         │                         │──────────────────────>│                       │                        │
         │                         │                       │                       │                        │
         │                         │                       │  updateProductPrices( │                        │
         │                         │                       │    products)          │                        │
         │                         │                       │──────────────────────>│                        │
         │                         │                       │                       │                        │
         │                         │                       │                       │  _enqueue(task)         │
         │                         │                       │                       │                        │
         │                         │                       │                       │  _loadModels() → Hive  │
         │                         │                       │                       │──────────────────────>│
         │                         │                       │                       │                        │
         │                         │                       │                       │  Compare prices:       │
         │                         │                       │                       │  for each cart item,   │
         │                         │                       │                       │  check if matching     │
         │                         │                       │                       │  product has different │
         │                         │                       │                       │  price                 │
         │                         │                       │                       │                        │
         │                         │                       │                       │  IF hasChanges:        │
         │                         │                       │                       │    _saveModels()       │
         │                         │                       │                       │──────────────────────>│
         │                         │                       │                       │                        │
         │                         │                       │  Right(null)          │                        │
         │                         │                       │<──────────────────────│                        │
         │                         │                       │                       │                        │
         │                         │  Either result        │                       │                        │
         │                         │<──────────────────────│                       │                        │
         │                         │                       │                       │                        │
         │                         │  fold: onSuccess →    │                       │                        │
         │                         │    loadCartUseCase()  │                       │                        │
         │                         │    → emit(CartLoaded) │                       │                        │
         │                         │                       │                       │                        │
         │  UI updates cart badge  │                       │                       │                        │
         │  and totals if on       │                       │                        │                        │
         │  cart page              │                       │                       │                        │
         │<────────────────────────│                       │                       │                        │
```

**Key observation**: `syncPrices` only saves to Hive and re-emits state if at least one price actually changed (`hasChanges` flag). This avoids unnecessary Hive writes and state emissions when prices haven't changed.
