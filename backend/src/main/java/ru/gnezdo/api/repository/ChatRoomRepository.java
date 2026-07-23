package ru.gnezdo.api.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.gnezdo.api.model.ChatRoom;

public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {}
