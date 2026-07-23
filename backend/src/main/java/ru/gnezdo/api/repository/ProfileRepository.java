package ru.gnezdo.api.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.gnezdo.api.model.Profile;

public interface ProfileRepository extends JpaRepository<Profile, Long> {}
