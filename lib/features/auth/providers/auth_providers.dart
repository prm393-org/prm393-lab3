/// Auth feature providers.
///
/// `authServiceProvider` / `authStateProvider` sống ở
/// `lib/firebase/firebase_providers.dart` (dùng chung router + Profile).
library;

export '../../../firebase/firebase_providers.dart'
    show authServiceProvider, authStateProvider;
export '../presentation/viewmodels/auth_state.dart'
    show AuthState, AuthStatus;
export '../presentation/viewmodels/auth_viewmodel.dart'
    show AuthViewModel, authViewModelProvider;
