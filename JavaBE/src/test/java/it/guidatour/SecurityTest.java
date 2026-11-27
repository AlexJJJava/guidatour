package it.guidatour;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

/** Verifica le regole di base di SecurityConfig: chiuso di default, pubblico solo ciò che è dichiarato. */
@SpringBootTest
@AutoConfigureMockMvc
class SecurityTest {

    @Autowired
    MockMvc mvc;

    @Test
    void healthPubblico() throws Exception {
        mvc.perform(get("/actuator/health")).andExpect(status().isOk());
    }

    @Test
    void apiProtetteSenzaAutenticazione401() throws Exception {
        mvc.perform(get("/api/tours/mine")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/public/qualcosa")).andExpect(status().isUnauthorized());
    }

    @Test
    void endpointActuatorNonEspostiChiusi() throws Exception {
        mvc.perform(get("/actuator/env")).andExpect(status().isUnauthorized());
    }

    @Test
    void headerDiSicurezza() throws Exception {
        mvc.perform(get("/actuator/health"))
            .andExpect(header().string("X-Content-Type-Options", "nosniff"))
            .andExpect(header().string("X-Frame-Options", "DENY"))
            .andExpect(header().string("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'"));
    }
}
