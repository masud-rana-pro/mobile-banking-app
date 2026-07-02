package com.smartkash.firebase;

import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import org.springframework.stereotype.Service;

@Service
public class FirebaseTokenVerifierImpl implements FirebaseTokenVerifier {

    private final FirebaseAdminInitializer firebaseAdminInitializer;

    public FirebaseTokenVerifierImpl(FirebaseAdminInitializer firebaseAdminInitializer) {
        this.firebaseAdminInitializer = firebaseAdminInitializer;
    }

    @Override
    public FirebaseToken verifyIdToken(String idToken) throws FirebaseAuthException {
        FirebaseApp firebaseApp = firebaseAdminInitializer.firebaseApp()
                .orElseThrow(() -> new IllegalStateException("Firebase Admin SDK is not configured."));

        return FirebaseAuth.getInstance(firebaseApp).verifyIdToken(idToken);
    }
}
