package ru.gnezdo.api.repository;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import ru.gnezdo.api.model.ConfirmedMatch;

public interface ConfirmedMatchRepository extends JpaRepository<ConfirmedMatch, Long> {
    Optional<ConfirmedMatch> findByProfileIdAndRequesterName(Long profileId, String requesterName);
}
