package com.zoripay.api.crypto;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.security.SecureRandom;
import java.util.Arrays;

public final class EncryptionService {

    private static final int IV_LENGTH = 12;
    private static final int AUTH_TAG_BITS = 128;
    private static final int AUTH_TAG_BYTES = 16;

    private EncryptionService() {}

    public record EncryptedSeed(byte[] ciphertext, byte[] iv, byte[] authTag) {}

    /**
     * Encrypt a 64-byte seed using AES-256-GCM.
     * Format is byte-compatible with Rust: ciphertext || 16-byte auth tag.
     */
    public static EncryptedSeed encryptSeed(byte[] seed, byte[] key) {
        if (key.length != 32) {
            throw new IllegalArgumentException("Encryption key must be 32 bytes");
        }
        if (seed.length != 64) {
            throw new IllegalArgumentException("Seed must be 64 bytes");
        }

        try {
            byte[] iv = new byte[IV_LENGTH];
            new SecureRandom().nextBytes(iv);

            var cipher = Cipher.getInstance("AES/GCM/NoPadding");
            var keySpec = new SecretKeySpec(key, "AES");
            var gcmSpec = new GCMParameterSpec(AUTH_TAG_BITS, iv);
            cipher.init(Cipher.ENCRYPT_MODE, keySpec, gcmSpec);

            // JDK AES-GCM appends auth tag to ciphertext (same as Rust aes-gcm crate)
            byte[] ciphertextWithTag = cipher.doFinal(seed);

            // Split: ciphertext (len - 16) + auth tag (last 16)
            int ctLen = ciphertextWithTag.length - AUTH_TAG_BYTES;
            byte[] ciphertext = Arrays.copyOfRange(ciphertextWithTag, 0, ctLen);
            byte[] authTag = Arrays.copyOfRange(ciphertextWithTag, ctLen, ciphertextWithTag.length);

            return new EncryptedSeed(ciphertext, iv, authTag);
        } catch (Exception e) {
            throw new RuntimeException("Encryption failed", e);
        }
    }

    /**
     * Decrypt an encrypted seed using AES-256-GCM.
     * Verifies the authentication tag for integrity.
     */
    public static byte[] decryptSeed(EncryptedSeed encrypted, byte[] key) {
        if (key.length != 32) {
            throw new IllegalArgumentException("Decryption key must be 32 bytes");
        }

        try {
            // Reconstruct ciphertext with tag (same format as Rust)
            byte[] ciphertextWithTag = new byte[encrypted.ciphertext().length + encrypted.authTag().length];
            System.arraycopy(encrypted.ciphertext(), 0, ciphertextWithTag, 0,
                    encrypted.ciphertext().length);
            System.arraycopy(encrypted.authTag(), 0, ciphertextWithTag,
                    encrypted.ciphertext().length, encrypted.authTag().length);

            var cipher = Cipher.getInstance("AES/GCM/NoPadding");
            var keySpec = new SecretKeySpec(key, "AES");
            var gcmSpec = new GCMParameterSpec(AUTH_TAG_BITS, encrypted.iv());
            cipher.init(Cipher.DECRYPT_MODE, keySpec, gcmSpec);

            byte[] plaintext = cipher.doFinal(ciphertextWithTag);

            if (plaintext.length != 64) {
                throw new RuntimeException("Decrypted seed has invalid length: " + plaintext.length);
            }

            return plaintext;
        } catch (Exception e) {
            throw new RuntimeException("Decryption failed", e);
        }
    }
}
