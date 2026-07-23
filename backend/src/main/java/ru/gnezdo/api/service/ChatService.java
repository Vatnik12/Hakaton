package ru.gnezdo.api.service;

import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import ru.gnezdo.api.dto.DtoMapper;
import ru.gnezdo.api.dto.MessageDto;
import ru.gnezdo.api.dto.RoomCreatedDto;
import ru.gnezdo.api.dto.SendMessageRequest;
import ru.gnezdo.api.model.ChatMessage;
import ru.gnezdo.api.model.ChatRoom;
import ru.gnezdo.api.model.Listing;
import ru.gnezdo.api.model.Profile;
import ru.gnezdo.api.model.RoomType;
import ru.gnezdo.api.repository.ChatMessageRepository;
import ru.gnezdo.api.repository.ChatRoomRepository;

@Service
public class ChatService {
    private final ChatRoomRepository roomRepository;
    private final ChatMessageRepository messageRepository;
    private final ProfileService profileService;
    private final ListingService listingService;

    public ChatService(ChatRoomRepository roomRepository, ChatMessageRepository messageRepository,
                       ProfileService profileService, ListingService listingService) {
        this.roomRepository = roomRepository;
        this.messageRepository = messageRepository;
        this.profileService = profileService;
        this.listingService = listingService;
    }

    @Transactional
    public RoomCreatedDto createPersonChat(Long profileId, String requesterName) {
        Profile profile = profileService.requireEntity(profileId);
        return toCreated(createPersonRoom(profile, requesterName));
    }

    @Transactional
    public RoomCreatedDto createListingChat(Long listingId, String requesterName) {
        Listing listing = listingService.requireEntity(listingId);
        ChatRoom room = roomRepository.save(new ChatRoom(RoomType.LISTING, listing, null, listing.getAddress()));
        messageRepository.save(new ChatMessage(room, listing.getOwner(),
            "Здравствуйте! Расскажите о себе и желаемой дате заселения."));
        return toCreated(room);
    }

    @Transactional(readOnly = true)
    public List<MessageDto> messages(Long roomId) {
        requireRoom(roomId);
        return messageRepository.findByRoomIdOrderByCreatedAtAscIdAsc(roomId)
            .stream().map(DtoMapper::toDto).toList();
    }

    @Transactional
    public MessageDto send(Long roomId, SendMessageRequest request) {
        ChatRoom room = requireRoom(roomId);
        return DtoMapper.toDto(messageRepository.save(new ChatMessage(room, request.sender(), request.text())));
    }

    ChatRoom createPersonRoom(Profile profile, String requesterName) {
        ChatRoom room = roomRepository.save(new ChatRoom(RoomType.PERSON, null, profile,
            requesterName + " + " + profile.getName()));
        messageRepository.save(new ChatMessage(room, profile.getName(),
            "Привет! Вижу, у нас есть сильные совпадения. Что для тебя важнее всего в совместной аренде?"));
        return room;
    }

    @Transactional(readOnly = true)
    public ChatRoom requireRoom(Long roomId) {
        return roomRepository.findById(roomId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Chat room not found"));
    }

    private static RoomCreatedDto toCreated(ChatRoom room) {
        return new RoomCreatedDto(room.getId(), room.getRoomType().name());
    }
}
