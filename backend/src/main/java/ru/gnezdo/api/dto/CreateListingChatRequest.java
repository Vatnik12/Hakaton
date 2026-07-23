package ru.gnezdo.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreateListingChatRequest(@NotNull Long listingId, @NotBlank String requesterName) {}
