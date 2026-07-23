package ru.gnezdo.api.dto;

import java.time.OffsetDateTime;

public record MessageDto(long id, long roomId, String sender, String text, OffsetDateTime createdAt) {}
