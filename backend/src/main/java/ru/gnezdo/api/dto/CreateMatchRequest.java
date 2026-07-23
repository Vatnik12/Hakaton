package ru.gnezdo.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreateMatchRequest(@NotNull Long profileId, @NotBlank String requesterName, Long roomId) {}
