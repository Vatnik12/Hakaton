package ru.gnezdo.api.dto;

import ru.gnezdo.api.model.ChatMessage;
import ru.gnezdo.api.model.Listing;
import ru.gnezdo.api.model.Profile;

public final class DtoMapper {
    private DtoMapper() {}

    public static ListingDto toDto(Listing item) {
        return new ListingDto(item.getId(), item.getTitle(), item.getAddress(), item.getDistrict(),
            item.getPrice(), item.getRooms(), item.getArea(), item.getDistance(), item.getSlots(),
            item.getImage(), item.getOwner(), item.getResidentName(), item.getTraits(), item.getRedFlags());
    }

    public static ProfileDto toDto(Profile item) {
        return new ProfileDto(item.getId(), item.getName(), item.getAge(), item.getRole(), item.getDistrict(),
            item.getBudget(), item.getDistance(), item.getAvatar(), item.isVerified(), item.getBio(),
            item.getTraits(), item.getRedFlags());
    }

    public static MessageDto toDto(ChatMessage item) {
        return new MessageDto(item.getId(), item.getRoom().getId(), item.getSender(), item.getText(), item.getCreatedAt());
    }
}
