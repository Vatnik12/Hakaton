package ru.gnezdo.api.controller;

import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import ru.gnezdo.api.dto.CreateListingRequest;
import ru.gnezdo.api.dto.ListingDto;
import ru.gnezdo.api.service.ListingService;

@RestController
@RequestMapping("/api/v1/listings")
public class ListingController {
    private final ListingService service;

    public ListingController(ListingService service) { this.service = service; }

    @GetMapping
    public List<ListingDto> find(@RequestParam(required = false) String district,
                                 @RequestParam(required = false) Integer maxPrice,
                                 @RequestParam(defaultValue = "1") Integer minSlots,
                                 @RequestParam(defaultValue = "128") Integer limit) {
        return service.find(district, maxPrice, minSlots, limit);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ListingDto create(@Valid @RequestBody CreateListingRequest request) {
        return service.create(request);
    }
}
