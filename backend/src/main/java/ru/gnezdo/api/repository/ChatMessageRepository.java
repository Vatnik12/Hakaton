package ru.gnezdo.api.repository;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import ru.gnezdo.api.model.ChatMessage;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {
    List<ChatMessage> findByRoomIdOrderByCreatedAtAscIdAsc(Long roomId);
}
