package com.zoripay.api.crypto;

import org.web3j.crypto.Bip32ECKeyPair;
import org.web3j.crypto.Keys;
import org.web3j.crypto.MnemonicUtils;

import java.security.SecureRandom;

public final class WalletService {

    private WalletService() {}

    public record GeneratedWallet(String mnemonic, byte[] seed, String polygonAddress) {}

    // BIP-44 path constants: m/44'/60'/0'/0/{index}
    private static final int[] BIP44_PATH = {
            44 | Bip32ECKeyPair.HARDENED_BIT,   // purpose
            60 | Bip32ECKeyPair.HARDENED_BIT,   // coin type (Ethereum/EVM)
            0 | Bip32ECKeyPair.HARDENED_BIT,    // account
            0                                     // external chain
    };

    /**
     * Generate a new BIP-39 wallet with 12-word mnemonic and derive the first Polygon address.
     */
    public static GeneratedWallet generateWallet() {
        // Generate 128-bit entropy for 12-word mnemonic
        byte[] entropy = new byte[16];
        new SecureRandom().nextBytes(entropy);

        String mnemonic = MnemonicUtils.generateMnemonic(entropy);

        // Derive 512-bit seed (no passphrase)
        byte[] seed = MnemonicUtils.generateSeed(mnemonic, "");

        // Derive Polygon address
        String address = derivePolygonAddress(seed, 0);

        return new GeneratedWallet(mnemonic, seed, address);
    }

    /**
     * Derive a Polygon (EVM) address from a BIP-39 seed.
     * Derivation path: m/44'/60'/0'/0/{index}
     */
    public static String derivePolygonAddress(byte[] seed, int index) {
        var masterKeyPair = Bip32ECKeyPair.generateKeyPair(seed);
        var derivedKeyPair = Bip32ECKeyPair.deriveKeyPair(masterKeyPair, BIP44_PATH);
        var addressKeyPair = Bip32ECKeyPair.deriveKeyPair(derivedKeyPair,
                new int[]{index});

        // web3j Keys.getAddress computes keccak256 of the public key and takes last 20 bytes
        String address = Keys.getAddress(addressKeyPair);
        return "0x" + address;
    }

    /**
     * Derive the private key bytes from a BIP-39 seed.
     * Derivation path: m/44'/60'/0'/0/{index}
     */
    public static byte[] derivePrivateKey(byte[] seed, int index) {
        var masterKeyPair = Bip32ECKeyPair.generateKeyPair(seed);
        var derivedKeyPair = Bip32ECKeyPair.deriveKeyPair(masterKeyPair, BIP44_PATH);
        var addressKeyPair = Bip32ECKeyPair.deriveKeyPair(derivedKeyPair,
                new int[]{index});

        byte[] privateKeyBytes = addressKeyPair.getPrivateKey().toByteArray();

        // BigInteger may have a leading sign byte; ensure exactly 32 bytes
        if (privateKeyBytes.length == 33 && privateKeyBytes[0] == 0) {
            byte[] trimmed = new byte[32];
            System.arraycopy(privateKeyBytes, 1, trimmed, 0, 32);
            return trimmed;
        } else if (privateKeyBytes.length < 32) {
            byte[] padded = new byte[32];
            System.arraycopy(privateKeyBytes, 0, padded, 32 - privateKeyBytes.length,
                    privateKeyBytes.length);
            return padded;
        }
        return privateKeyBytes;
    }
}
