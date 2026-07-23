package ru.gnezdo.api.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.gnezdo.api.dto.HealthDto;
import ru.gnezdo.api.dto.MetaDto;
import ru.gnezdo.api.repository.ChatRoomRepository;
import ru.gnezdo.api.repository.ListingRepository;
import ru.gnezdo.api.repository.ProfileRepository;

@Service
public class SystemService {
    private final ListingRepository listings;
    private final ProfileRepository profiles;
    private final ChatRoomRepository rooms;

    public SystemService(ListingRepository listings, ProfileRepository profiles, ChatRoomRepository rooms) {
        this.listings = listings;
        this.profiles = profiles;
        this.rooms = rooms;
    }

    @Transactional(readOnly = true)
    public HealthDto health() {
        try {
            profiles.count();
            return new HealthDto("UP", "gnezdo-api", "UP");
        } catch (RuntimeException exception) {
            return new HealthDto("DOWN", "gnezdo-api", "DOWN");
        }
    }

    @Transactional(readOnly = true)
    public MetaDto meta() {
        return new MetaDto(listings.count(), profiles.count(), rooms.count(), "PostgreSQL 17",
            "Java 21 / Spring Boot 3.5 / Spring Data JPA");
    }
}
