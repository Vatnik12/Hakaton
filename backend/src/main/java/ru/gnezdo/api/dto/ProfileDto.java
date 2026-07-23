package ru.gnezdo.api.dto;

import java.math.BigDecimal;
import java.util.List;

public record ProfileDto(long id, String name, int age, String role, String district, int budget,
                         BigDecimal distance, String avatar, boolean verified, String bio,
                         List<String> traits, List<String> redFlags) {}
