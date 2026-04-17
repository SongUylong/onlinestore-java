package com.uylongsong.notificationservice.service;

import com.uylongsong.notificationservice.event.OrderPlacedEvent;
import com.uylongsong.notificationservice.model.Notification;
import com.uylongsong.notificationservice.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final JavaMailSender javaMailSender;
    private final NotificationRepository notificationRepository;

    @KafkaListener(topics = "notificationTopic")
    public void handleNotification(OrderPlacedEvent orderPlacedEvent) {
        log.info("Processing Notification for Order - {}", orderPlacedEvent.getOrderNumber());

        String status = "SENT";
        try {
            sendEmail(orderPlacedEvent.getOrderNumber(), "customer@example.com");
            log.info("Email sent successfully for Order - {}", orderPlacedEvent.getOrderNumber());
        } catch (Exception e) {
            log.error("Failed to send email for Order - {}", orderPlacedEvent.getOrderNumber(), e);
            status = "FAILED";
        }

        // Save notification history to MongoDB
        Notification notification = Notification.builder()
                .orderNumber(orderPlacedEvent.getOrderNumber())
                .recipientEmail("customer@example.com")
                .status(status)
                .sentTime(LocalDateTime.now())
                .build();

        notificationRepository.save(notification);
    }

    private void sendEmail(String orderNumber, String email) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom("shop@onlinestore.com");
        message.setTo(email);
        message.setSubject("Order Confirmation - " + orderNumber);
        message.setText("Thank you for your order! Your order number is: " + orderNumber);

        javaMailSender.send(message);
    }
}
