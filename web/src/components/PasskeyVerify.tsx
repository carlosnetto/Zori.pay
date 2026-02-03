import React, { useEffect, useState } from 'react';
import { authService } from '../services/auth';
import { Language, translations } from '../translations';

interface PasskeyVerifyProps {
  currentLang: Language;
  onSuccess: () => void;
  onCancel: () => void;
}

// Helper functions for WebAuthn
function base64UrlDecode(base64url: string): ArrayBuffer {
  const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/');
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

function base64UrlEncode(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

const PasskeyVerify: React.FC<PasskeyVerifyProps> = ({ currentLang, onSuccess, onCancel }) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const t = translations[currentLang].auth;

  useEffect(() => {
    // TEMPORARY: Skip passkey verification and get real tokens
    const bypassPasskeyAndGetTokens = async () => {
      try {
        setLoading(true);
        console.log('[PasskeyVerify] Bypassing passkey, requesting real tokens...');

        // Call the verifyPasskey with null data - API should handle gracefully
        // For now, we'll manually call a simplified endpoint
        const response = await authService.verifyPasskeyBypass();

        console.log('[PasskeyVerify] Got real tokens successfully');
        onSuccess();
      } catch (err: any) {
        console.error('[PasskeyVerify] Failed to get tokens:', err);
        setError(err.message || 'Failed to authenticate');
        setLoading(false);
      }
    };

    bypassPasskeyAndGetTokens();
  }, []);

  const handlePasskeyVerification = async () => {
    setLoading(true);
    setError(null);

    try {
      // Get challenge from server
      const challenge = await authService.requestPasskeyChallenge();

      // Use WebAuthn API to get credential
      const credential = await navigator.credentials.get({
        publicKey: {
          challenge: base64UrlDecode(challenge.challenge),
          allowCredentials: challenge.allowed_credentials.map((c: any) => ({
            type: c.type,
            id: base64UrlDecode(c.id),
            transports: c.transports,
          })),
          userVerification: challenge.user_verification,
          timeout: challenge.timeout,
        },
      }) as any;

      if (!credential) {
        throw new Error('No credential selected');
      }

      // Verify with server
      await authService.verifyPasskey({
        credential_id: base64UrlEncode(credential.rawId),
        authenticator_data: base64UrlEncode(credential.response.authenticatorData),
        client_data_json: base64UrlEncode(credential.response.clientDataJSON),
        signature: base64UrlEncode(credential.response.signature),
        user_handle: credential.response.userHandle
          ? base64UrlEncode(credential.response.userHandle)
          : null,
      });

      onSuccess();
    } catch (err: any) {
      setError(err.message || 'Passkey verification failed');
      console.error('Passkey error:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm"></div>
      <div className="bg-white rounded-3xl p-8 max-w-sm w-full relative z-10 shadow-2xl">
        <div className="text-center mb-6">
          <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
            {loading ? (
              <svg className="animate-spin h-8 w-8 text-blue-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
            ) : error ? (
              <svg className="h-8 w-8 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            ) : (
              <svg className="h-8 w-8 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
            )}
          </div>
          <h3 className="text-2xl font-bold text-gray-900 mb-2">
            {error ? 'Verification Failed' : t.passkeyTitle || 'Verify with Passkey'}
          </h3>
          <p className="text-gray-600 text-sm">
            {error ? error : loading ? (t.passkeyWait || 'Waiting for passkey...') : 'Ready to verify'}
          </p>
        </div>

        {error && (
          <div className="space-y-3">
            <button
              onClick={handlePasskeyVerification}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 rounded-xl transition-colors"
            >
              {t.passkeyRetry || 'Try Again'}
            </button>
            <button
              onClick={onCancel}
              className="w-full bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold py-3 rounded-xl transition-colors"
            >
              {t.passkeyCancel || 'Cancel'}
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default PasskeyVerify;
