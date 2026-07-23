package ru.gnezdo.api.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "chat_messages")
public class ChatMessage {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "room_id", nullable = false) private ChatRoom room;
    @Column(nullable = false, length = 120) private String sender;
    @Column(name = "message_text", nullable = false, columnDefinition = "text") private String text;
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false) private OffsetDateTime createdAt;

    protected ChatMessage() {}

    public ChatMessage(ChatRoom room, String sender, String text) {
        this.room = room;
        this.sender = sender;
        this.text = text;
    }

    public Long getId() { return id; }
    public ChatRoom getRoom() { return room; }
    public String getSender() { return sender; }
    public String getText() { return text; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
}
