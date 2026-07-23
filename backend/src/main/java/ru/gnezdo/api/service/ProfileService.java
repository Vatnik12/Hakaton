package ru.gnezdo.api.service;

import java.util.List;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import ru.gnezdo.api.dto.DtoMapper;
import ru.gnezdo.api.dto.ProfileDto;
import ru.gnezdo.api.model.Profile;
import ru.gnezdo.api.repository.ProfileRepository;

@Service
public class ProfileService {
    private final ProfileRepository repository;

    public ProfileService(ProfileRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public List<ProfileDto> find(Integer limit) {
        int safeLimit = Math.min(Math.max(limit == null ? 50 : limit, 1), 200);
        return repository.findAll(PageRequest.of(0, safeLimit, Sort.by("id")))
            .stream().map(DtoMapper::toDto).toList();
    }

    @Transactional(readOnly = true)
    public Profile requireEntity(Long id) {
        return repository.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Profile not found"));
    }
}
