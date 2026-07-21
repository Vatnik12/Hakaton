package ru.gnezdo.api;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

public final class ApiModels {
    private ApiModels() {}
    public record Listing(long id,String title,String address,String district,int price,int rooms,int area,BigDecimal distance,int slots,String image,String owner,String residentName,List<String> traits,List<String> redFlags) {}
    public record Profile(long id,String name,int age,String role,String district,int budget,BigDecimal distance,String avatar,boolean verified,String bio,List<String> traits,List<String> redFlags) {}
    public record Message(long id,long roomId,String sender,String text,OffsetDateTime createdAt) {}
    public record Meta(long listings,long profiles,long chatRooms,String database,String runtime) {}
    public record CreateListingRequest(@NotBlank String title,@NotBlank String address,@NotBlank String district,@Positive int price,@Min(1) @Max(10) int rooms,@Min(10) int area,@Min(1) @Max(10) int slots,String image,@NotBlank String owner,List<String> traits,List<String> redFlags) {}
    public record CreateMatchRequest(@NotNull Long profileId,@NotBlank String requesterName) {}
    public record CreateListingChatRequest(@NotNull Long listingId,@NotBlank String requesterName) {}
    public record SendMessageRequest(@NotBlank String sender,@NotBlank String text) {}
    public record RoomCreated(long roomId,String type) {}
}
