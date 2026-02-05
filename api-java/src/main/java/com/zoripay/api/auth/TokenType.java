package com.zoripay.api.auth;

public enum TokenType {
    INTERMEDIATE("intermediate"),
    ACCESS("access"),
    REFRESH("refresh");

    private final String value;

    TokenType(String value) {
        this.value = value;
    }

    public String value() {
        return value;
    }

    public static TokenType fromValue(String value) {
        for (var t : values()) {
            if (t.value.equals(value)) return t;
        }
        throw new IllegalArgumentException("Unknown token type: " + value);
    }
}
