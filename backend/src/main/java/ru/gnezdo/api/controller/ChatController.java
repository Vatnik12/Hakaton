package ru.gnezdo.api.controller;

import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import ru.gnezdo.api.dto.CreateListingChatRequest;
import ru.gnezdo.api.dto.CreatePersonChatRequest;
import ru.gnezdo.api.dto.MessageDto;
import ru.gnezdo.api.dto.RoomCreatedDto;
import ru.gnezdo.api.dto.SendMessageRequest;
import ru.gnezdo.api.service.ChatService;

@RestController
@RequestMapping("/api/v1/chats")
public class ChatController {
    private final ChatService service;

    public ChatController(ChatService service) { this.service = service; }

    @PostMapping("/person")
    @ResponseStatus(HttpStatus.CREATED)
    public RoomCreatedDto createPerson(@Valid @RequestBody CreatePersonChatRequest request) {
        return service.createPersonChat(request.profileId(), request.requesterName());
    }

    @PostMapping("/listing")
    @ResponseStatus(HttpStatus.CREATED)
    public RoomCreatedDto createListing(@Valid @RequestBody CreateListingChatRequest request) {
        return service.createListingChat(request.listingId(), request.requesterName());
    }

    @GetMapping("/{roomId}/messages")
    public List<MessageDto> messages(@PathVariable Long roomId) {
        return service.messages(roomId);
    }

    @PostMapping("/{roomId}/messages")
    @ResponseStatus(HttpStatus.CREATED)
    public MessageDto send(@PathVariable Long roomId, @Valid @RequestBody SendMessageRequest request) {
        return service.send(roomId, request);
    }
}
