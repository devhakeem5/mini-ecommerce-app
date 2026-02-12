import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_commerce_app/core/localization/app_localizations.dart';
import 'package:mini_commerce_app/presentation/cart/cubit/cart_cubit.dart';

import '../../../core/network/connectivity_cubit.dart';
import '../../../core/network/connectivity_state.dart';
import '../../../core/util/responsive.dart';
import '../../common/widgets/offline_indicator.dart';
import '../../common/widgets/offline_widget.dart';
import '../../common/widgets/skeleton_loaders.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';
import '../widgets/product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<SearchCubit>().loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final currentState = context.read<SearchCubit>().state;
      if (currentState is SearchResultsLoaded && currentState.hasReachedMax) return;
      context.read<SearchCubit>().loadMoreResults();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<SearchCubit, SearchState>(
              listener: (context, state) {
                if (state is SearchResultsLoaded) {
                  context.read<CartCubit>().syncPrices(state.products);
                  if (state.loadMoreError != null) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr(state.loadMoreError!)),
                        action: SnackBarAction(
                          label: context.tr('retry'),
                          onPressed: () => context.read<SearchCubit>().loadMoreResults(),
                        ),
                      ),
                    );
                  }
                }
              },
            ),
            BlocListener<ConnectivityCubit, ConnectivityState>(
              listenWhen: (previous, current) =>
                  previous is ConnectivityOffline && current is ConnectivityOnline,
              listener: (context, connState) {
                final searchState = context.read<SearchCubit>().state;
                if (searchState is SearchResultsLoaded && searchState.loadMoreError != null) {
                  context.read<SearchCubit>().loadMoreResults();
                }
              },
            ),
          ],
          child: Column(
            children: [
              _buildSearchBar(context),
              BlocBuilder<ConnectivityCubit, ConnectivityState>(
                builder: (context, connState) {
                  if (connState is ConnectivityOffline) {
                    final searchState = context.watch<SearchCubit>().state;
                    final hasResults =
                        searchState is SearchResultsLoaded && searchState.products.isNotEmpty;
                    if (hasResults) {
                      return const OfflineIndicator();
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
              Expanded(
                child: BlocBuilder<SearchCubit, SearchState>(
                  builder: (context, state) {
                    if (state is SearchLoading) {
                      return ProductGridSkeleton(
                        crossAxisCount: context.responsiveValue(mobile: 2, tablet: 3, desktop: 4),
                      );
                    } else if (state is SearchHistoryLoaded) {
                      return _buildHistoryAndSuggestions(context, state);
                    } else if (state is SearchResultsLoaded) {
                      return _buildSearchResults(state);
                    } else if (state is SearchError) {
                      if (state.message.toLowerCase().contains('internet') ||
                          context.read<ConnectivityCubit>().state is ConnectivityOffline) {
                        return OfflineWidget(
                          onRetry: () {
                            final query = _searchController.text.trim();
                            if (query.isNotEmpty) {
                              context.read<SearchCubit>().search(query);
                            }
                          },
                        );
                      }
                      return Center(child: Text(state.message));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios),
          ),
          Expanded(
            child: Hero(
              tag: 'search_bar',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: 54,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    onChanged: (val) => context.read<SearchCubit>().onSearchChanged(val),
                    onSubmitted: (val) => context.read<SearchCubit>().search(val),
                    decoration: InputDecoration(
                      hintText: context.tr('search_hint'),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                context.read<SearchCubit>().onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryAndSuggestions(BuildContext context, SearchHistoryLoaded state) {
    final list = _searchController.text.isEmpty ? state.history : state.suggestions;
    final isHistory = _searchController.text.isEmpty;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              isHistory ? context.tr('no_history') : context.tr('no_results'),
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            isHistory ? context.tr('recent_searches') : context.tr('suggestions'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
            itemBuilder: (context, index) {
              final item = list[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(item),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: () => context.read<SearchCubit>().deleteHistoryItem(item),
                ),
                onTap: () {
                  _searchController.text = item;
                  context.read<SearchCubit>().search(item);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(SearchResultsLoaded state) {
    if (state.products.isEmpty) {
      if (state.isOffline || context.read<ConnectivityCubit>().state is ConnectivityOffline) {
        return OfflineWidget(
          onRetry: () {
            final query = _searchController.text.trim();
            if (query.isNotEmpty) {
              context.read<SearchCubit>().search(query);
            }
          },
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              context.tr('no_results'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('try_another'),
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: context.responsiveValue(mobile: 2, tablet: 3, desktop: 4),
                  childAspectRatio: context.responsiveValue(
                    mobile: 0.65,
                    tablet: 0.75,
                    desktop: 0.9,
                  ),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ProductCard(product: state.products[index]),
                  childCount: state.products.length,
                ),
              ),
            ),
            if (state.loadMoreError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          context.tr(state.loadMoreError!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => context.read<SearchCubit>().loadMoreResults(),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(context.tr('retry')),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (state.hasReachedMax)
              SliverToBoxAdapter(
                child: state.wasPagingAttempted
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            context.tr('reached_end'),
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              )
            else
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
