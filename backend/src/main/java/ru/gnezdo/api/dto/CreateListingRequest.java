package ru.gnezdo.api.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import java.util.List;

public record CreateListingRequest(
    @NotBlank String title,
    @NotBlank String address,
    @NotBlank String district,
    @Positive int price,
    @Min(1) @Max(10) int rooms,
    @Min(10) int area,
    @Min(1) @Max(10) int slots,
    String image,
    @NotBlank String owner,
    List<String> traits,
    List<String> redFlags
) {}
