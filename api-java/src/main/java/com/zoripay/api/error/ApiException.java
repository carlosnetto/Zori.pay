package com.zoripay.api.error;

public class ApiException extends RuntimeException {
    private final ApiError apiError;

    public ApiException(ApiError apiError) {
        super(apiError.message());
        this.apiError = apiError;
    }

    public ApiException(ApiError apiError, Throwable cause) {
        super(apiError.message(), cause);
        this.apiError = apiError;
    }

    public ApiError getApiError() {
        return apiError;
    }

    // Factory methods for common errors
    public static ApiException userNotFound() {
        return new ApiException(new ApiError.UserNotFound());
    }

    public static ApiException invalidToken() {
        return new ApiException(new ApiError.InvalidToken());
    }

    public static ApiException invalidAuthCode() {
        return new ApiException(new ApiError.InvalidAuthCode());
    }

    public static ApiException validation(String message) {
        return new ApiException(new ApiError.Validation(message));
    }

    public static ApiException internal(String message) {
        return new ApiException(new ApiError.Internal(message));
    }

    public static ApiException internal(String message, Throwable cause) {
        return new ApiException(new ApiError.Internal(message), cause);
    }

    public static ApiException database(String message, Throwable cause) {
        return new ApiException(new ApiError.Database(message), cause);
    }
}
