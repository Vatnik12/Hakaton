package ru.gnezdo.api.config;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import ru.gnezdo.api.model.Listing;
import ru.gnezdo.api.model.Profile;
import ru.gnezdo.api.repository.ListingRepository;
import ru.gnezdo.api.repository.ProfileRepository;

@Component
public class DataSeeder implements ApplicationRunner {
    private static final String[] DISTRICTS = {"Центральный", "Фестивальный", "Юбилейный", "Черёмушки", "Панорама", "Энка", "ККБ", "Российский"};
    private static final String[] STREETS = {"Красная", "Северная", "Российская", "Ставропольская", "Тургенева", "Кубанская Набережная", "Восточно-Кругликовская", "Петра Метальникова"};
    private static final String[] NAMES = {"Алина", "Максим", "София", "Илья", "Мария", "Тимур", "Дарья", "Роман", "Ксения", "Никита", "Валерия", "Артём", "Анна", "Георгий", "Полина", "Денис", "Майя", "Лев", "Элина", "Вадим"};
    private static final String[] ROLES = {"UX-дизайнер", "Backend-разработчик", "Маркетолог", "Архитектор", "Фотограф", "Продуктовый аналитик", "Редактор", "Инженер", "Психолог", "Студент магистратуры", "HR-партнёр", "Видеограф", "Финансовый консультант", "Шеф-повар", "Иллюстратор", "Руководитель проектов", "Врач-ординатор", "Саунд-дизайнер", "Куратор выставок", "Авиадиспетчер"};
    private static final String[] TAGS = {"clean", "non_smoker", "pets", "pet_friendly", "quiet", "remote", "student", "early", "cooking", "sport", "long", "music"};

    private final ProfileRepository profiles;
    private final ListingRepository listings;

    public DataSeeder(ProfileRepository profiles, ListingRepository listings) {
        this.profiles = profiles;
        this.listings = listings;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (profiles.count() == 0) seedProfiles();
        if (listings.count() == 0) seedListings();
    }

    private void seedProfiles() {
        List<Profile> batch = new ArrayList<>(50);
        for (int i = 0; i < 50; i++) {
            String name = NAMES[i % NAMES.length] + (i >= NAMES.length ? " " + (i + 1) : "");
            batch.add(new Profile(name, 19 + i % 16, ROLES[i % ROLES.length], DISTRICTS[i % DISTRICTS.length],
                22000 + i % 7 * 4000, BigDecimal.valueOf(.8 + (i % 13) * .8),
                "https://api.dicebear.com/9.x/notionists/svg?seed=" + i, i % 4 != 0,
                "Ищу уютное жильё в Краснодаре. Ценю честность, личные границы и понятные бытовые правила.",
                tags(i, 4), tags(i + 5, 2)));
        }
        profiles.saveAll(batch);
    }

    private void seedListings() {
        String[] titles = {"Светлая квартира с панорамными окнами", "Уютная квартира рядом с парком", "Современная квартира в новом доме", "Просторная квартира для совместной аренды"};
        String[] owners = {"Ирина", "Александр", "Марина", "Олег"};
        List<Listing> batch = new ArrayList<>(128);
        for (int i = 0; i < 128; i++) {
            batch.add(new Listing(titles[i % titles.length], "ул. " + STREETS[i % STREETS.length] + ", " + (10 + (i * 13) % 190),
                DISTRICTS[i % DISTRICTS.length], 36000 + i % 12 * 4500, 1 + i % 4, 38 + i % 65,
                BigDecimal.valueOf(.6 + (i % 20) * .65), 1 + i % 3,
                "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80&sig=" + i,
                owners[i % owners.length], i % 3 == 0 ? NAMES[(i + 3) % NAMES.length] : null,
                tags(i + 2, 4), tags(i + 8, 2)));
        }
        listings.saveAll(batch);
    }

    private List<String> tags(int seed, int count) {
        List<String> result = new ArrayList<>(count);
        for (int i = 0; i < count; i++) result.add(TAGS[(seed + i * 3) % TAGS.length]);
        return result;
    }
}
