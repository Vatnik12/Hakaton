package ru.gnezdo.api.dto;

import java.math.BigDecimal;
import java.util.List;

public record ListingDto(long id, String title, String address, String district, int price, int rooms,
                         int area, BigDecimal distance, int slots, String image, String owner,
                         String residentName, List<String> traits, List<String> redFlags) {}
