package com.zoripay.api.model;

import java.time.LocalDate;
import java.util.UUID;

public record Person(UUID id, String fullName, LocalDate dateOfBirth, String emailAddress) {}
