package ru.gnezdo.api.dto;

import jakarta.validation.constraints.NotBlank;

public record SendMessageRequest(@NotBlank String sender, @NotBlank String text) {}
