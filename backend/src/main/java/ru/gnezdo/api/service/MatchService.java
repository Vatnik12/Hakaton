package ru.gnezdo.api.service;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import ru.gnezdo.api.dto.CreateMatchRequest;
import ru.gnezdo.api.dto.RoomCreatedDto;
import ru.gnezdo.api.model.ChatRoom;
import ru.gnezdo.api.model.ConfirmedMatch;
import ru.gnezdo.api.model.Profile;
import ru.gnezdo.api.model.RoomType;
import ru.gnezdo.api.repository.ConfirmedMatchRepository;

@Service
public class MatchService {
    private final ConfirmedMatchRepository repository;
    private final ProfileService profileService;
    private final ChatService chatService;

    public MatchService(ConfirmedMatchRepository repository, ProfileService profileService, ChatService chatService) {
        this.repository = repository;
        this.profileService = profileService;
        this.chatService = chatService;
    }

    @Transactional
    public RoomCreatedDto confirm(CreateMatchRequest request) {
        Profile profile = profileService.requireEntity(request.profileId());
        ChatRoom room = request.roomId() == null
            ? chatService.createPersonRoom(profile, request.requesterName())
            : chatService.requireRoom(request.roomId());
        if (room.getRoomType() != RoomType.PERSON || room.getProfile() == null
            || !room.getProfile().getId().equals(profile.getId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Person chat does not match profile");
        }
        ConfirmedMatch match = repository.findByProfileIdAndRequesterName(profile.getId(), request.requesterName())
            .orElseGet(() -> new ConfirmedMatch(profile, request.requesterName(), room));
        match.confirm(room);
        repository.save(match);
        return new RoomCreatedDto(room.getId(), RoomType.PERSON.name());
    }
}
