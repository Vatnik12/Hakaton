package ru.gnezdo.api.service;

import jakarta.persistence.criteria.Predicate;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import ru.gnezdo.api.dto.CreateListingRequest;
import ru.gnezdo.api.dto.DtoMapper;
import ru.gnezdo.api.dto.ListingDto;
import ru.gnezdo.api.model.Listing;
import ru.gnezdo.api.repository.ListingRepository;

@Service
public class ListingService {
    private static final String DEFAULT_IMAGE = "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80";
    private final ListingRepository repository;

    public ListingService(ListingRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public List<ListingDto> find(String district, Integer maxPrice, Integer minSlots, Integer limit) {
        int safeSlots = Math.max(1, minSlots == null ? 1 : minSlots);
        int safeLimit = Math.min(Math.max(limit == null ? 128 : limit, 1), 500);
        Specification<Listing> filters = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (district != null && !district.isBlank()) {
                predicates.add(cb.equal(cb.lower(root.<String>get("district")), district.trim().toLowerCase()));
            }
            if (maxPrice != null) predicates.add(cb.lessThanOrEqualTo(root.<Integer>get("price"), maxPrice));
            predicates.add(cb.greaterThanOrEqualTo(root.<Integer>get("slots"), safeSlots));
            return cb.and(predicates.toArray(Predicate[]::new));
        };
        return repository.findAll(filters, PageRequest.of(0, safeLimit, Sort.by("id")))
            .stream().map(DtoMapper::toDto).toList();
    }

    @Transactional
    public ListingDto create(CreateListingRequest request) {
        Listing listing = new Listing(request.title(), request.address(), request.district(), request.price(),
            request.rooms(), request.area(), BigDecimal.valueOf(0.5), request.slots(),
            request.image() == null || request.image().isBlank() ? DEFAULT_IMAGE : request.image(),
            request.owner(), null, request.traits(), request.redFlags());
        return DtoMapper.toDto(repository.save(listing));
    }

    @Transactional(readOnly = true)
    public Listing requireEntity(Long id) {
        return repository.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Listing not found"));
    }
}
