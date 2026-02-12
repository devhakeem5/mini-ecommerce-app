import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/locale/get_locale_usecase.dart';
import '../../../domain/usecases/locale/set_locale_usecase.dart';

class LocaleState {
  final String languageCode;
  const LocaleState({this.languageCode = 'en'});
}

class LocaleCubit extends Cubit<LocaleState> {
  final GetLocaleUseCase getLocaleUseCase;
  final SetLocaleUseCase setLocaleUseCase;

  LocaleCubit({required this.getLocaleUseCase, required this.setLocaleUseCase})
    : super(const LocaleState()) {
    _loadSavedLocale();
  }

  void _loadSavedLocale() {
    final saved = getLocaleUseCase();
    emit(LocaleState(languageCode: saved));
  }

  void setLocale(String code) {
    setLocaleUseCase(code);
    emit(LocaleState(languageCode: code));
  }

  void toggleLocale() {
    final newCode = state.languageCode == 'en' ? 'ar' : 'en';
    setLocale(newCode);
  }

  String get currentLanguageName => state.languageCode == 'ar' ? 'العربية' : 'English';
}
