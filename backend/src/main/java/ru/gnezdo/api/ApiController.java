package ru.gnezdo.api;

import static ru.gnezdo.api.ApiModels.*;

import jakarta.validation.Valid;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.OffsetDateTime;
import java.util.*;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1")
public class ApiController {
    private final JdbcClient jdbc;
    public ApiController(JdbcClient jdbc){this.jdbc=jdbc;}

    @GetMapping("/health")
    public Map<String,Object> health(){return Map.of("status","UP","service","gnezdo-api","database",jdbc.sql("select 1").query(Integer.class).single()==1?"UP":"DOWN");}

    @GetMapping("/meta")
    public Meta meta(){return new Meta(count("listings"),count("profiles"),count("chat_rooms"),"PostgreSQL 17","Java 21 / Spring Boot 3.5");}

    @GetMapping("/listings")
    public List<Listing> listings(@RequestParam(required=false) String district,@RequestParam(required=false) Integer maxPrice,@RequestParam(defaultValue="1") Integer minSlots,@RequestParam(defaultValue="128") Integer limit){
        return jdbc.sql("select * from listings order by id").query(this::mapListing).list().stream()
            .filter(x->district==null||district.isBlank()||x.district().equalsIgnoreCase(district))
            .filter(x->maxPrice==null||x.price()<=maxPrice).filter(x->x.slots()>=Math.max(1,minSlots))
            .limit(Math.min(Math.max(limit,1),500)).toList();
    }

    @PostMapping("/listings") @ResponseStatus(HttpStatus.CREATED)
    public Listing createListing(@Valid @RequestBody CreateListingRequest r){
        Long id=jdbc.sql("insert into listings(title,address,district,price,rooms,area,distance,slots,image,owner,resident_name,traits,red_flags) values (:title,:address,:district,:price,:rooms,:area,0.5,:slots,:image,:owner,null,:traits,:redFlags) returning id")
            .param("title",r.title()).param("address",r.address()).param("district",r.district()).param("price",r.price()).param("rooms",r.rooms()).param("area",r.area()).param("slots",r.slots()).param("image",defaultImage(r.image())).param("owner",r.owner()).param("traits",join(r.traits())).param("redFlags",join(r.redFlags())).query(Long.class).single();
        return listingById(id);
    }

    @GetMapping("/profiles")
    public List<Profile> profiles(@RequestParam(defaultValue="50") Integer limit){return jdbc.sql("select * from profiles order by id limit :limit").param("limit",Math.min(Math.max(limit,1),200)).query(this::mapProfile).list();}

    @PostMapping("/matches") @Transactional @ResponseStatus(HttpStatus.CREATED)
    public RoomCreated createMatch(@Valid @RequestBody CreateMatchRequest r){Profile p=profileById(r.profileId());long room=createRoom("PERSON",null,p.id(),r.requesterName()+" + "+p.name());addMessage(room,p.name(),"Привет! У нас высокий процент совместимости. Давай познакомимся?");return new RoomCreated(room,"PERSON");}

    @PostMapping("/chats/listing") @Transactional @ResponseStatus(HttpStatus.CREATED)
    public RoomCreated createListingChat(@Valid @RequestBody CreateListingChatRequest r){Listing l=listingById(r.listingId());long room=createRoom("LISTING",l.id(),null,l.address());addMessage(room,l.owner(),"Здравствуйте! Расскажите о себе и желаемой дате заселения.");return new RoomCreated(room,"LISTING");}

    @GetMapping("/chats/{roomId}/messages")
    public List<Message> messages(@PathVariable long roomId){ensureRoom(roomId);return jdbc.sql("select * from chat_messages where room_id=:roomId order by created_at,id").param("roomId",roomId).query(this::mapMessage).list();}

    @PostMapping("/chats/{roomId}/messages") @Transactional @ResponseStatus(HttpStatus.CREATED)
    public Message send(@PathVariable long roomId,@Valid @RequestBody SendMessageRequest r){ensureRoom(roomId);long id=addMessage(roomId,r.sender(),r.text());return jdbc.sql("select * from chat_messages where id=:id").param("id",id).query(this::mapMessage).single();}

    private long createRoom(String type,Long listingId,Long profileId,String title){return jdbc.sql("insert into chat_rooms(room_type,listing_id,profile_id,title) values (:type,:listingId,:profileId,:title) returning id").param("type",type).param("listingId",listingId,Types.BIGINT).param("profileId",profileId,Types.BIGINT).param("title",title).query(Long.class).single();}
    private long addMessage(long roomId,String sender,String text){return jdbc.sql("insert into chat_messages(room_id,sender,message_text) values (:roomId,:sender,:text) returning id").param("roomId",roomId).param("sender",sender).param("text",text).query(Long.class).single();}
    private void ensureRoom(long id){if(jdbc.sql("select count(*) from chat_rooms where id=:id").param("id",id).query(Long.class).single()==0)throw new ResponseStatusException(HttpStatus.NOT_FOUND,"Chat room not found");}
    private Listing listingById(long id){return jdbc.sql("select * from listings where id=:id").param("id",id).query(this::mapListing).optional().orElseThrow(()->new ResponseStatusException(HttpStatus.NOT_FOUND,"Listing not found"));}
    private Profile profileById(long id){return jdbc.sql("select * from profiles where id=:id").param("id",id).query(this::mapProfile).optional().orElseThrow(()->new ResponseStatusException(HttpStatus.NOT_FOUND,"Profile not found"));}
    private long count(String table){return jdbc.sql("select count(*) from "+table).query(Long.class).single();}
    private Listing mapListing(ResultSet rs,int row)throws SQLException{return new Listing(rs.getLong("id"),rs.getString("title"),rs.getString("address"),rs.getString("district"),rs.getInt("price"),rs.getInt("rooms"),rs.getInt("area"),rs.getBigDecimal("distance"),rs.getInt("slots"),rs.getString("image"),rs.getString("owner"),rs.getString("resident_name"),split(rs.getString("traits")),split(rs.getString("red_flags")));}
    private Profile mapProfile(ResultSet rs,int row)throws SQLException{return new Profile(rs.getLong("id"),rs.getString("name"),rs.getInt("age"),rs.getString("role"),rs.getString("district"),rs.getInt("budget"),rs.getBigDecimal("distance"),rs.getString("avatar"),rs.getBoolean("verified"),rs.getString("bio"),split(rs.getString("traits")),split(rs.getString("red_flags")));}
    private Message mapMessage(ResultSet rs,int row)throws SQLException{return new Message(rs.getLong("id"),rs.getLong("room_id"),rs.getString("sender"),rs.getString("message_text"),rs.getObject("created_at",OffsetDateTime.class));}
    private static String join(List<String> values){return values==null?"":String.join(",",values);}
    private static List<String> split(String value){return value==null||value.isBlank()?List.of():Arrays.stream(value.split(",")).map(String::trim).filter(s->!s.isBlank()).toList();}
    private static String defaultImage(String image){return image==null||image.isBlank()?"https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80":image;}
}
