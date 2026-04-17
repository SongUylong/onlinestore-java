package com.uylongsong.notificationservice.repository;

import com.uylongsong.notificationservice.model.Notification;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface NotificationRepository extends MongoRepository<Notification, String> {
}
