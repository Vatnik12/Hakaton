package ru.gnezdo.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreatePersonChatRequest(@NotNull Long profileId, @NotBlank String requesterName) {}
