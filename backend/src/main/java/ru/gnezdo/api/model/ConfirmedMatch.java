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
import jakarta.persistence.UniqueConstraint;
import java.time.OffsetDateTime;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "matches", uniqueConstraints = @UniqueConstraint(columnNames = {"profile_id", "requester_name"}))
public class ConfirmedMatch {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "profile_id", nullable = false) private Profile profile;
    @Column(name = "requester_name", nullable = false, length = 120) private String requesterName;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "room_id", nullable = false) private ChatRoom room;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30) private MatchStatus status;
    @CreationTimestamp
    @Column(name = "confirmed_at", nullable = false) private OffsetDateTime confirmedAt;

    protected ConfirmedMatch() {}

    public ConfirmedMatch(Profile profile, String requesterName, ChatRoom room) {
        this.profile = profile;
        this.requesterName = requesterName;
        this.room = room;
        this.status = MatchStatus.CONFIRMED;
    }

    public void confirm(ChatRoom room) {
        this.room = room;
        this.status = MatchStatus.CONFIRMED;
        this.confirmedAt = OffsetDateTime.now();
    }

    public Long getId() { return id; }
    public Profile getProfile() { return profile; }
    public String getRequesterName() { return requesterName; }
    public ChatRoom getRoom() { return room; }
    public MatchStatus getStatus() { return status; }
    public OffsetDateTime getConfirmedAt() { return confirmedAt; }
}
