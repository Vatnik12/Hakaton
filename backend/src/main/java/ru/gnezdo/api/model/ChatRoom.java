package ru.gnezdo.api.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
@Table(name = "chat_rooms")
public class ChatRoom {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Enumerated(EnumType.STRING)
    @Column(name = "room_type", nullable = false, length = 30) private RoomType roomType;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "listing_id") private Listing listing;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "profile_id") private Profile profile;
    @Column(nullable = false, length = 240) private String title;
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false) private OffsetDateTime createdAt;

    protected ChatRoom() {}

    public ChatRoom(RoomType roomType, Listing listing, Profile profile, String title) {
        this.roomType = roomType;
        this.listing = listing;
        this.profile = profile;
        this.title = title;
    }

    public Long getId() { return id; }
    public RoomType getRoomType() { return roomType; }
    public Listing getListing() { return listing; }
    public Profile getProfile() { return profile; }
    public String getTitle() { return title; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
}
