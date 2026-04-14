package com.uylongsong.orderservice.repository;

import com.uylongsong.orderservice.model.Order;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface OrderRepository extends JpaRepository<Order, Long> {

    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.orderLineItemsList")
    List<Order> findAllWithLineItems();
}
