package it.guidatour;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;

/**
 * Avvio del backend GuidaTour.
 * <p>
 * Monolite modulare: un package per modulo funzionale sotto {@code it.guidatour}
 * (vedi i {@code package-info.java}). I moduli dipendono l'uno dall'altro in una sola direzione
 * (identità ← offerta ← domanda/collaborazione), così in futuro si possono separare in microservizi.
 * <p>
 * Estende {@link SpringBootServletInitializer} per poter essere installato come WAR su un Tomcat esterno.
 */
@SpringBootApplication
public class GuidaTourApplication extends SpringBootServletInitializer {

    public static void main(String[] args) {
        SpringApplication.run(GuidaTourApplication.class, args);
    }

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder builder) {
        return builder.sources(GuidaTourApplication.class);
    }
}
