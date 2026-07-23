package ru.gnezdo.api.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.gnezdo.api.dto.HealthDto;
import ru.gnezdo.api.dto.MetaDto;
import ru.gnezdo.api.service.SystemService;

@RestController
@RequestMapping("/api/v1")
public class SystemController {
    private final SystemService service;

    public SystemController(SystemService service) { this.service = service; }

    @GetMapping("/health")
    public HealthDto health() { return service.health(); }

    @GetMapping("/meta")
    public MetaDto meta() { return service.meta(); }
}
