package ru.gnezdo.api.model;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "profiles")
public class Profile {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, length = 120) private String name;
    @Column(nullable = false) private int age;
    @Column(nullable = false, length = 160) private String role;
    @Column(nullable = false, length = 120) private String district;
    @Column(nullable = false) private int budget;
    @Column(nullable = false, precision = 7, scale = 2) private BigDecimal distance;
    @Column(nullable = false, columnDefinition = "text") private String avatar;
    @Column(nullable = false) private boolean verified;
    @Column(nullable = false, columnDefinition = "text") private String bio;
    @Convert(converter = StringListConverter.class)
    @Column(nullable = false, columnDefinition = "text") private List<String> traits = List.of();
    @Convert(converter = StringListConverter.class)
    @Column(name = "red_flags", nullable = false, columnDefinition = "text") private List<String> redFlags = List.of();
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false) private OffsetDateTime createdAt;

    protected Profile() {}

    public Profile(String name, int age, String role, String district, int budget, BigDecimal distance,
                   String avatar, boolean verified, String bio, List<String> traits, List<String> redFlags) {
        this.name = name;
        this.age = age;
        this.role = role;
        this.district = district;
        this.budget = budget;
        this.distance = distance;
        this.avatar = avatar;
        this.verified = verified;
        this.bio = bio;
        this.traits = traits == null ? List.of() : List.copyOf(traits);
        this.redFlags = redFlags == null ? List.of() : List.copyOf(redFlags);
    }

    public Long getId() { return id; }
    public String getName() { return name; }
    public int getAge() { return age; }
    public String getRole() { return role; }
    public String getDistrict() { return district; }
    public int getBudget() { return budget; }
    public BigDecimal getDistance() { return distance; }
    public String getAvatar() { return avatar; }
    public boolean isVerified() { return verified; }
    public String getBio() { return bio; }
    public List<String> getTraits() { return traits; }
    public List<String> getRedFlags() { return redFlags; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
}
