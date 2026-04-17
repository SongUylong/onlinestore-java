package com.uylongsong.notificationservice.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Document(value = "notification")
@AllArgsConstructor
@NoArgsConstructor
@Builder
@Data
public class Notification {
    @Id
    private String id;
    private String orderNumber;
    private String recipientEmail;
    private String status;
    private LocalDateTime sentTime;
}
