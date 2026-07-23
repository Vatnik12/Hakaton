package ru.gnezdo.api;

import java.math.BigDecimal;
import java.sql.Types;
import org.springframework.boot.*;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
public class DataSeeder implements ApplicationRunner {
    private static final String[] DISTRICTS={"Центральный","Фестивальный","Юбилейный","Черёмушки","Панорама","Энка","ККБ","Российский"};
    private static final String[] STREETS={"Красная","Северная","Российская","Ставропольская","Тургенева","Кубанская Набережная","Восточно-Кругликовская","Петра Метальникова"};
    private static final String[] NAMES={"Алина","Максим","София","Илья","Мария","Тимур","Дарья","Роман","Ксения","Никита","Валерия","Артём","Анна","Георгий","Полина","Денис","Майя","Лев","Элина","Вадим"};
    private static final String[] ROLES={"UX-дизайнер","Backend-разработчик","Маркетолог","Архитектор","Фотограф","Продуктовый аналитик","Редактор","Инженер","Психолог","Студент магистратуры","HR-партнёр","Видеограф","Финансовый консультант","Шеф-повар","Иллюстратор","Руководитель проектов","Врач-ординатор","Саунд-дизайнер","Куратор выставок","Авиадиспетчер"};
    private static final String[] TAGS={"clean","non_smoker","pets","pet_friendly","quiet","remote","student","early","cooking","sport","long","music"};
    private final JdbcClient jdbc;
    public DataSeeder(JdbcClient jdbc){this.jdbc=jdbc;}
    @Override @Transactional public void run(ApplicationArguments args){if(jdbc.sql("select count(*) from profiles").query(Long.class).single()==0)seedProfiles();if(jdbc.sql("select count(*) from listings").query(Long.class).single()==0)seedListings();}
    private void seedProfiles(){for(int i=0;i<50;i++){String name=NAMES[i%NAMES.length]+(i>=NAMES.length?" "+(i+1):"");jdbc.sql("insert into profiles(name,age,role,district,budget,distance,avatar,verified,bio,traits,red_flags) values (:name,:age,:role,:district,:budget,:distance,:avatar,:verified,:bio,:traits,:redFlags)").param("name",name).param("age",19+i%16).param("role",ROLES[i%ROLES.length]).param("district",DISTRICTS[i%DISTRICTS.length]).param("budget",22000+i%7*4000).param("distance",BigDecimal.valueOf(.8+(i%13)*.8)).param("avatar","https://api.dicebear.com/9.x/notionists/svg?seed="+i).param("verified",i%4!=0).param("bio","Ищу уютное жильё в Краснодаре. Ценю честность, личные границы и понятные бытовые правила.").param("traits",tags(i,4)).param("redFlags",tags(i+5,2)).update();}}
    private void seedListings(){String[] titles={"Светлая квартира с панорамными окнами","Уютная квартира рядом с парком","Современная квартира в новом доме","Просторная квартира для совместной аренды"};for(int i=0;i<128;i++)jdbc.sql("insert into listings(title,address,district,price,rooms,area,distance,slots,image,owner,resident_name,traits,red_flags) values (:title,:address,:district,:price,:rooms,:area,:distance,:slots,:image,:owner,:resident,:traits,:redFlags)").param("title",titles[i%titles.length]).param("address","ул. "+STREETS[i%STREETS.length]+", "+(10+(i*13)%190)).param("district",DISTRICTS[i%DISTRICTS.length]).param("price",36000+i%12*4500).param("rooms",1+i%4).param("area",38+i%65).param("distance",BigDecimal.valueOf(.6+(i%20)*.65)).param("slots",1+i%3).param("image","https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80&sig="+i).param("owner",new String[]{"Ирина","Александр","Марина","Олег"}[i%4]).param("resident",i%3==0?NAMES[(i+3)%NAMES.length]:null,Types.VARCHAR).param("traits",tags(i+2,4)).param("redFlags",tags(i+8,2)).update();}
    private String tags(int seed,int count){StringBuilder out=new StringBuilder();for(int i=0;i<count;i++){if(i>0)out.append(',');out.append(TAGS[(seed+i*3)%TAGS.length]);}return out.toString();}
}
