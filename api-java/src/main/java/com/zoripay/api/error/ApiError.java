package com.zoripay.api.error;

public sealed interface ApiError {
    int httpStatus();
    String code();
    String message();

    record UserNotFound() implements ApiError {
        public int httpStatus() { return 404; }
        public String code() { return "USER_NOT_FOUND"; }
        public String message() { return "No account found for this email"; }
    }

    record EmailNotAuthorizedForLogin() implements ApiError {
        public int httpStatus() { return 403; }
        public String code() { return "EMAIL_NOT_AUTHORIZED"; }
        public String message() { return "This email is not authorized for login"; }
    }

    record InvalidAuthCode() implements ApiError {
        public int httpStatus() { return 401; }
        public String code() { return "INVALID_AUTH_CODE"; }
        public String message() { return "Invalid or expired authorization code"; }
    }

    record InvalidToken() implements ApiError {
        public int httpStatus() { return 401; }
        public String code() { return "INVALID_TOKEN"; }
        public String message() { return "Invalid or expired token"; }
    }

    record InvalidPasskeySignature() implements ApiError {
        public int httpStatus() { return 401; }
        public String code() { return "INVALID_PASSKEY"; }
        public String message() { return "Invalid passkey signature"; }
    }

    record PasskeyChallengeExpired() implements ApiError {
        public int httpStatus() { return 401; }
        public String code() { return "CHALLENGE_EXPIRED"; }
        public String message() { return "Passkey challenge has expired"; }
    }

    record NoPasskeysRegistered() implements ApiError {
        public int httpStatus() { return 403; }
        public String code() { return "NO_PASSKEYS"; }
        public String message() { return "No passkeys registered for this account"; }
    }

    record Validation(String detail) implements ApiError {
        public int httpStatus() { return 400; }
        public String code() { return "VALIDATION_ERROR"; }
        public String message() { return detail; }
    }

    record CpfAlreadyExists() implements ApiError {
        public int httpStatus() { return 409; }
        public String code() { return "CPF_ALREADY_EXISTS"; }
        public String message() { return "CPF is already registered"; }
    }

    record InvalidCpf(String detail) implements ApiError {
        public int httpStatus() { return 400; }
        public String code() { return "INVALID_CPF"; }
        public String message() { return detail; }
    }

    record InvalidEmail() implements ApiError {
        public int httpStatus() { return 400; }
        public String code() { return "INVALID_EMAIL"; }
        public String message() { return "Invalid email format"; }
    }

    record InvalidPhone() implements ApiError {
        public int httpStatus() { return 400; }
        public String code() { return "INVALID_PHONE"; }
        public String message() { return "Invalid phone format"; }
    }

    record MissingFile(String field) implements ApiError {
        public int httpStatus() { return 400; }
        public String code() { return "MISSING_FILE"; }
        public String message() { return field; }
    }

    record FileTooLarge(String detail) implements ApiError {
        public int httpStatus() { return 413; }
        public String code() { return "FILE_TOO_LARGE"; }
        public String message() { return detail; }
    }

    record InvalidRequest(String detail) implements ApiError {
        public int httpStatus() { return 400; }
        public String code() { return "INVALID_REQUEST"; }
        public String message() { return detail; }
    }

    record WalletGenerationError() implements ApiError {
        public int httpStatus() { return 500; }
        public String code() { return "WALLET_ERROR"; }
        public String message() { return "Failed to generate wallet"; }
    }

    record EncryptionError() implements ApiError {
        public int httpStatus() { return 500; }
        public String code() { return "ENCRYPTION_ERROR"; }
        public String message() { return "Failed to encrypt data"; }
    }

    record DriveError(String detail) implements ApiError {
        public int httpStatus() { return 500; }
        public String code() { return "DRIVE_ERROR"; }
        public String message() { return "Failed to upload documents"; }
    }

    record Internal(String detail) implements ApiError {
        public int httpStatus() { return 500; }
        public String code() { return "INTERNAL_ERROR"; }
        public String message() { return "An internal error occurred"; }
    }

    record Database(String detail) implements ApiError {
        public int httpStatus() { return 500; }
        public String code() { return "DATABASE_ERROR"; }
        public String message() { return "A database error occurred"; }
    }
}
