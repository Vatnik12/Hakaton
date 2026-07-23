package ru.gnezdo.api.controller;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import ru.gnezdo.api.dto.CreateMatchRequest;
import ru.gnezdo.api.dto.RoomCreatedDto;
import ru.gnezdo.api.service.MatchService;

@RestController
@RequestMapping("/api/v1/matches")
public class MatchController {
    private final MatchService service;

    public MatchController(MatchService service) { this.service = service; }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public RoomCreatedDto confirm(@Valid @RequestBody CreateMatchRequest request) {
        return service.confirm(request);
    }
}
