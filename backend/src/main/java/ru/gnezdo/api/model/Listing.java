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
@Table(name = "listings")
public class Listing {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, length = 240) private String title;
    @Column(nullable = false, length = 240) private String address;
    @Column(nullable = false, length = 120) private String district;
    @Column(nullable = false) private int price;
    @Column(nullable = false) private int rooms;
    @Column(nullable = false) private int area;
    @Column(nullable = false, precision = 7, scale = 2) private BigDecimal distance;
    @Column(nullable = false) private int slots;
    @Column(nullable = false, columnDefinition = "text") private String image;
    @Column(nullable = false, length = 120) private String owner;
    @Column(name = "resident_name", length = 120) private String residentName;
    @Convert(converter = StringListConverter.class)
    @Column(nullable = false, columnDefinition = "text") private List<String> traits = List.of();
    @Convert(converter = StringListConverter.class)
    @Column(name = "red_flags", nullable = false, columnDefinition = "text") private List<String> redFlags = List.of();
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false) private OffsetDateTime createdAt;

    protected Listing() {}

    public Listing(String title, String address, String district, int price, int rooms, int area,
                   BigDecimal distance, int slots, String image, String owner, String residentName,
                   List<String> traits, List<String> redFlags) {
        this.title = title;
        this.address = address;
        this.district = district;
        this.price = price;
        this.rooms = rooms;
        this.area = area;
        this.distance = distance;
        this.slots = slots;
        this.image = image;
        this.owner = owner;
        this.residentName = residentName;
        this.traits = traits == null ? List.of() : List.copyOf(traits);
        this.redFlags = redFlags == null ? List.of() : List.copyOf(redFlags);
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public String getAddress() { return address; }
    public String getDistrict() { return district; }
    public int getPrice() { return price; }
    public int getRooms() { return rooms; }
    public int getArea() { return area; }
    public BigDecimal getDistance() { return distance; }
    public int getSlots() { return slots; }
    public String getImage() { return image; }
    public String getOwner() { return owner; }
    public String getResidentName() { return residentName; }
    public List<String> getTraits() { return traits; }
    public List<String> getRedFlags() { return redFlags; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
}
