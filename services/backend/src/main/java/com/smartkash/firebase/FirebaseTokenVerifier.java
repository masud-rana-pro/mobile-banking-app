package com.smartkash.firebase;

import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;

public interface FirebaseTokenVerifier {

    FirebaseToken verifyIdToken(String idToken) throws FirebaseAuthException;
}
