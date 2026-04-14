package com.uylongsong.orderservice.repository;

import com.uylongsong.orderservice.model.Order;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderRepository extends JpaRepository<Order, Long> {
}
