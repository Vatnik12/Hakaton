package ru.gnezdo.api.controller;

import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import ru.gnezdo.api.dto.ProfileDto;
import ru.gnezdo.api.service.ProfileService;

@RestController
@RequestMapping("/api/v1/profiles")
public class ProfileController {
    private final ProfileService service;

    public ProfileController(ProfileService service) { this.service = service; }

    @GetMapping
    public List<ProfileDto> find(@RequestParam(defaultValue = "50") Integer limit) {
        return service.find(limit);
    }
}
